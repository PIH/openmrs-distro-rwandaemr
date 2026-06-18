class LabOrderListActions {

    /**
     * Fetches encounter obs (with groupMembers) and concept setMembers for each order, then
     * assembles a list of enriched orders using the same lookup logic as recordLabResults:
     *   - isPanel = orderable.setMembers.length > 0
     *   - tests   = isPanel ? orderable.setMembers : [orderable]
     *   - per test: obs where concept matches AND (obs.order == this order OR obs has no order)
     *
     * Resolves to:
     *   [{order, conceptName, fulfillerStatus, encounterLabId, isPanel,
     *     tests: [{concept, obs: [obs]}]}]
     */
    static buildOrderResults(orders) {
        var encounterRep =
            'uuid,encounterDatetime,obs:(uuid,obsDatetime,concept:(uuid,display,displayStringForLab,units),' +
            'order:(uuid),valueCoded:(uuid,display,displayStringForLab),valueNumeric,valueText,' +
            'valueDatetime,comment,referenceRange,' +
            'groupMembers:(uuid,obsDatetime,concept:(uuid,display,displayStringForLab,units),' +
            'order:(uuid),valueCoded:(uuid,display,displayStringForLab),valueNumeric,valueText,' +
            'valueDatetime,comment,referenceRange))';

        var conceptRep =
            'uuid,display,displayStringForLab,setMembers:(uuid,display,displayStringForLab,units)';

        var encounterUuids = [], conceptUuids = [];
        orders.forEach(function(order) {
            if (order.fulfillerEncounter) {
                var eu = order.fulfillerEncounter.uuid;
                if (encounterUuids.indexOf(eu) === -1) encounterUuids.push(eu);
            }
            var cu = order.concept.uuid;
            if (conceptUuids.indexOf(cu) === -1) conceptUuids.push(cu);
        });

        var encPromises = encounterUuids.map(function(uuid) {
            return new Promise(function(resolve) {
                jq.get(openmrsContextPath + '/ws/rest/v1/encounter/' + uuid +
                        '?v=custom:(' + encounterRep + ')')
                    .done(function(data) { resolve(data); })
                    .fail(function() { resolve(null); });
            });
        });

        var conceptPromises = conceptUuids.map(function(uuid) {
            return new Promise(function(resolve) {
                jq.get(openmrsContextPath + '/ws/rest/v1/concept/' + uuid +
                        '?v=custom:(' + conceptRep + ')')
                    .done(function(data) { resolve(data); })
                    .fail(function() { resolve(null); });
            });
        });

        var configPromise = new Promise(function(resolve) {
            jq.get(openmrsContextPath + '/ws/rest/v1/pihapps/config?v=custom:(labOrderConfig:(labIdentifierConcept:(uuid)))')
                .done(function(data) { resolve(data); })
                .fail(function() { resolve(null); });
        });

        return Promise.all([configPromise, Promise.all(encPromises), Promise.all(conceptPromises)])
            .then(function(results) {
                var config = results[0];
                var labIdConceptUuid = config && config.labOrderConfig && config.labOrderConfig.labIdentifierConcept
                    ? config.labOrderConfig.labIdentifierConcept.uuid : null;

                // encounterMap: uuid -> { encounter, flatObs, labId }
                var encounterMap = {};
                results[1].filter(Boolean).forEach(function(encounter) {
                    var flatObs = (encounter.obs || []).reduce(function(acc, o) {
                        acc.push(o);
                        if (o.groupMembers && o.groupMembers.length > 0) {
                            o.groupMembers.forEach(function(m) { acc.push(m); });
                        }
                        return acc;
                    }, []);
                    var labIdObs = labIdConceptUuid
                        ? flatObs.find(function(o) { return o.concept.uuid === labIdConceptUuid; })
                        : null;
                    encounterMap[encounter.uuid] = {
                        encounter: encounter,
                        flatObs:   flatObs,
                        labId:     labIdObs ? labIdObs.valueText : null
                    };
                });

                // conceptMap: uuid -> concept (with setMembers)
                var conceptMap = {};
                results[2].filter(Boolean).forEach(function(c) { conceptMap[c.uuid] = c; });

                return orders.map(function(order) {
                    var orderable = conceptMap[order.concept.uuid];
                    var setMembers = orderable && orderable.setMembers ? orderable.setMembers : [];
                    var isPanel = setMembers.length > 0;
                    var tests = isPanel ? setMembers : (orderable ? [orderable] : [{
                        uuid: order.concept.uuid,
                        display: order.concept.display,
                        displayStringForLab: order.concept.displayStringForLab
                    }]);

                    var encData = order.fulfillerEncounter
                        ? (encounterMap[order.fulfillerEncounter.uuid] || { flatObs: [], labId: null })
                        : { flatObs: [], labId: null };
                    var flatObs = encData.flatObs;

                    var enrichedTests = tests.map(function(test) {
                        // Mirror recordLabResults: prefer obs linked to this order, fall back to unlinked
                        var linked   = flatObs.filter(function(o) {
                            return o.concept.uuid === test.uuid && o.order && o.order.uuid === order.uuid;
                        });
                        var unlinked = flatObs.filter(function(o) {
                            return o.concept.uuid === test.uuid && !o.order;
                        });
                        var obs = (linked.length > 0 ? linked : unlinked).filter(function(o) {
                            return o.valueNumeric != null || o.valueCoded != null
                                || (o.valueText && o.valueText.trim()) || o.valueDatetime != null;
                        });
                        return { concept: test, obs: obs };
                    });

                    return {
                        order:           order,
                        conceptName:     orderable
                            ? (orderable.displayStringForLab || orderable.display)
                            : (order.concept.displayStringForLab || order.concept.display),
                        fulfillerStatus: order.fulfillerStatus,
                        encounterLabId:  encData.labId,
                        isPanel:         isPanel,
                        tests:           enrichedTests
                    };
                });
            });
    }

    static printResults(patientWithOrders, extensionParams) {
        if (typeof PDFLib === 'undefined') {
            emr.errorMessage('PDF library not available');
            return;
        }

        LabOrderListActions.buildOrderResults(patientWithOrders.orders).then(function(enrichedOrders) {
            return LabOrderListActions.generateLabPdf(patientWithOrders.patient, enrichedOrders);
        }).catch(function(err) {
            console.error('LabOrderListActions.printResults: failed to generate PDF', err);
            emr.errorMessage('Failed to generate PDF report');
        });
    }

    static async generateLabPdf(patient, enrichedOrders) {
        const { PDFDocument, StandardFonts, rgb } = PDFLib;

        const doc      = await PDFDocument.create();
        const fontReg  = await doc.embedFont(StandardFonts.Helvetica);
        const fontBold = await doc.embedFont(StandardFonts.HelveticaBold);
        const fontItal = await doc.embedFont(StandardFonts.HelveticaOblique);

        // A4 portrait dimensions in points
        const W = 595.28, H = 841.89;
        const ML = 40, MR = 40, MT = 50, MB = 40;
        const CW = W - ML - MR;

        // 5 columns: Test | Result | Units | Flag | Reference Range
        const COL_PCT     = [0.35, 0.16, 0.10, 0.12, 0.27];
        const COL_W       = COL_PCT.map(p => p * CW);
        const COL_X       = [];
        const COL_HEADERS = ['Test', 'Result', 'Units', 'Flag', 'Reference Range'];
        let colCursor = ML;
        COL_W.forEach(w => { COL_X.push(colCursor); colCursor += w; });

        // Colors
        const cHeaderBg   = rgb(0.267, 0.267, 0.267);
        const cHeaderText = rgb(1, 1, 1);
        const cPanelBg    = rgb(0.94, 0.94, 0.94);
        const cSectionBg  = rgb(0.86, 0.86, 0.86);
        const cBorder     = rgb(0.878, 0.878, 0.878);
        const cGrey       = rgb(0.4, 0.4, 0.4);
        const cRed        = rgb(0.627, 0, 0);
        const cOrange     = rgb(0.75, 0.35, 0);
        const cBlack      = rgb(0, 0, 0);

        // Font sizes and row heights
        const FS = 9, FS_SM = 8, FS_TITLE = 13;
        const RH = 16, RH_HDR = 18, RH_SECTION = 18, RH_COMMENT = 12;

        // Mutable page state
        let page = doc.addPage([W, H]);
        let y    = H - MT;

        // ---- Helpers ----

        function truncate(text, maxW, font, size) {
            if (!text) return '';
            text = String(text);
            if (font.widthOfTextAtSize(text, size) <= maxW) return text;
            while (text.length > 1 && font.widthOfTextAtSize(text.slice(0, -1) + '…', size) > maxW) {
                text = text.slice(0, -1);
            }
            return text.slice(0, -1) + '…';
        }

        function formatDate(d) {
            if (!d) return '';
            const date = typeof d === 'string' ? new Date(d) : d;
            if (isNaN(date.getTime())) return '';
            const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
            return date.getDate() + ' ' + months[date.getMonth()] + ' ' + date.getFullYear();
        }

        function formatDateTime(d) {
            if (!d) return '';
            const date = typeof d === 'string' ? new Date(d) : d;
            if (isNaN(date.getTime())) return '';
            const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
            const h = String(date.getHours()).padStart(2, '0');
            const m = String(date.getMinutes()).padStart(2, '0');
            return date.getDate() + ' ' + months[date.getMonth()] + ' ' + date.getFullYear() + ' ' + h + ':' + m;
        }

        function fmtResultValue(obs) {
            if (obs.valueNumeric != null) return String(obs.valueNumeric);
            if (obs.valueCoded) return obs.valueCoded.displayStringForLab || obs.valueCoded.display || '';
            if (obs.valueText)  return obs.valueText;
            return '';
        }

        function fmtUnits(obs) {
            if (obs.valueNumeric != null) return obs.concept.units || '';
            return '';
        }

        function fmtRange(obs) {
            const rr = obs.referenceRange;
            if (!rr) return '';
            if (rr.lowNormal != null && rr.hiNormal != null) return rr.lowNormal + ' – ' + rr.hiNormal;
            if (rr.lowNormal != null) return '>= ' + rr.lowNormal;
            if (rr.hiNormal  != null) return '<= ' + rr.hiNormal;
            return '';
        }

        function getFlagInfo(obs) {
            const rr = obs.referenceRange;
            const v  = obs.valueNumeric;
            if (!rr || v == null) return null;
            if ((rr.lowCritical != null && v < rr.lowCritical) || (rr.hiCritical != null && v > rr.hiCritical)) {
                return { label: 'Critical', color: cRed };
            }
            if ((rr.lowNormal != null && v < rr.lowNormal) || (rr.hiNormal != null && v > rr.hiNormal)) {
                return { label: 'Abnormal', color: cOrange };
            }
            return null;
        }

        // ---- Page / table management ----

        function drawTableHeader() {
            page.drawRectangle({ x: ML, y: y - RH_HDR, width: CW, height: RH_HDR, color: cHeaderBg });
            const textY = y - RH_HDR + (RH_HDR - FS_SM) / 2;
            COL_HEADERS.forEach((h, i) => {
                page.drawText(h, { x: COL_X[i] + 3, y: textY, size: FS_SM, font: fontBold, color: cHeaderText });
            });
            COL_X.slice(1).forEach(cx => {
                page.drawLine({ start: {x: cx, y}, end: {x: cx, y: y - RH_HDR}, thickness: 0.3, color: cGrey });
            });
            y -= RH_HDR;
        }

        function ensureSpace(needed) {
            if (y - needed < MB) {
                page = doc.addPage([W, H]);
                y    = H - MT;
                drawTableHeader();
            }
        }

        // cells: array indexed by column, each {text, bold, italic, color, indent} or {}
        function drawRow(cells, opts) {
            const rowH    = (opts && opts.rowHeight) || RH;
            const textPad = (opts && opts.textPad != null) ? opts.textPad : (rowH - FS) / 2;

            ensureSpace(rowH);

            if (opts && opts.bgColor) {
                page.drawRectangle({ x: ML, y: y - rowH, width: CW, height: rowH, color: opts.bgColor });
            }

            const textY = y - rowH + textPad;

            cells.forEach(function(cell, i) {
                if (!cell || !cell.text) return;
                const fnt    = cell.bold ? fontBold : (cell.italic ? fontItal : fontReg);
                const clr    = cell.color || cBlack;
                const indent = cell.indent || 0;
                const txt    = truncate(String(cell.text), COL_W[i] - 6 - indent, fnt, FS);
                page.drawText(txt, { x: COL_X[i] + 3 + indent, y: textY, size: FS, font: fnt, color: clr });
            });

            // Horizontal bottom border
            page.drawLine({ start: {x: ML, y: y - rowH}, end: {x: W - MR, y: y - rowH}, thickness: 0.3, color: cBorder });
            // Vertical left, column dividers, and right borders
            [...COL_X, W - MR].forEach(function(cx) {
                page.drawLine({ start: {x: cx, y}, end: {x: cx, y: y - rowH}, thickness: 0.3, color: cBorder });
            });
            y -= rowH;
        }

        // Draws a full-width section header band with an optional right-aligned label
        function drawSectionHeader(leftLabel, rightLabel) {
            // Need room for the section header + table header + at least one data row
            if (y - (RH_SECTION + RH_HDR + RH) < MB) {
                page = doc.addPage([W, H]);
                y    = H - MT;
            }
            y -= 8; // gap before section
            page.drawRectangle({ x: ML, y: y - RH_SECTION, width: CW, height: RH_SECTION, color: cSectionBg });
            const textY = y - RH_SECTION + (RH_SECTION - FS) / 2;
            page.drawText(leftLabel, { x: COL_X[0] + 3, y: textY, size: FS, font: fontBold, color: cBlack });
            if (rightLabel) {
                const rw = fontBold.widthOfTextAtSize(rightLabel, FS);
                page.drawText(rightLabel, { x: W - MR - rw - 8, y: textY, size: FS, font: fontBold, color: cBlack });
            }
            y -= RH_SECTION;
            drawTableHeader();
        }

        // ---- Document header ----

        const facilityName = (typeof visitLocationName !== 'undefined') ? visitLocationName : '';
        const patientName  = patient.person.display;
        const emrId = (() => {
            if (!patient.identifiers) return '';
            const pref = patient.identifiers.find(id => id.preferred);
            return pref ? pref.identifier : (patient.identifiers[0] ? patient.identifiers[0].identifier : '');
        })();
        const generatedDate = formatDate(new Date());

        if (facilityName) {
            const fw = fontBold.widthOfTextAtSize(facilityName, FS_TITLE);
            page.drawText(facilityName, { x: (W - fw) / 2, y, size: FS_TITLE, font: fontBold, color: cBlack });
            y -= 20;
        }

        const titleText = 'Laboratory Results';
        const titleW    = fontBold.widthOfTextAtSize(titleText, FS_TITLE);
        page.drawText(titleText, { x: (W - titleW) / 2, y, size: FS_TITLE, font: fontBold, color: cBlack });
        y -= 20;

        page.drawText('Patient: ' + patientName, { x: ML, y, size: FS, font: fontBold, color: cBlack });
        y -= 13;

        page.drawText('ID: ' + emrId, { x: ML, y, size: FS, font: fontBold, color: cBlack });
        const genText = 'Generated: ' + generatedDate;
        const genW    = fontReg.widthOfTextAtSize(genText, FS_SM);
        page.drawText(genText, { x: W - MR - genW, y, size: FS_SM, font: fontReg, color: cGrey });
        y -= 12;

        page.drawLine({ start: { x: ML, y }, end: { x: W - MR, y }, thickness: 0.5, color: cBorder });
        y -= 6;

        // ---- Group enrichedOrders by fulfiller encounter, sorted desc by specimen date ----

        const encounterGroups = [];
        const encounterGroupMap = {};
        const pendingOrders = [];

        enrichedOrders.forEach(function(eo) {
            const enc = eo.order.fulfillerEncounter;
            if (!enc) {
                pendingOrders.push(eo);
            } else {
                if (!encounterGroupMap[enc.uuid]) {
                    encounterGroupMap[enc.uuid] = {
                        specimenDatetime: enc.encounterDatetime,
                        labId:            eo.encounterLabId,
                        orders:           []
                    };
                    encounterGroups.push(encounterGroupMap[enc.uuid]);
                }
                encounterGroupMap[enc.uuid].orders.push(eo);
            }
        });

        encounterGroups.sort(function(a, b) {
            return new Date(b.specimenDatetime) - new Date(a.specimenDatetime);
        });

        // ---- Render each encounter group as its own section ----

        function estimateEncounterHeight(group) {
            let h = 8 + RH_SECTION + RH_HDR; // gap + section header + table header
            group.orders.forEach(function(eo) {
                if (eo.isPanel) {
                    h += RH; // panel header row
                    eo.tests.forEach(function(test) {
                        if (test.obs.length === 0) {
                            h += RH;
                        } else {
                            test.obs.forEach(function(obs) {
                                h += RH;
                                if (obs.comment && obs.comment.trim()) h += RH_COMMENT;
                            });
                        }
                    });
                } else {
                    const obsArr = eo.tests[0] ? eo.tests[0].obs : [];
                    if (obsArr.length === 0) {
                        h += RH;
                    } else {
                        obsArr.forEach(function(obs) {
                            h += RH;
                            if (obs.comment && obs.comment.trim()) h += RH_COMMENT;
                        });
                    }
                }
            });
            return h;
        }

        function renderOrderRows(eo) {
            const { conceptName, isPanel, tests } = eo;

            if (isPanel) {
                drawRow([
                    { text: conceptName, bold: true },
                    {}, {}, {}, {}
                ], { bgColor: cPanelBg });

                tests.forEach(function(test) {
                    const testName = test.concept.displayStringForLab || test.concept.display;
                    if (test.obs.length === 0) {
                        drawRow([{ text: testName, indent: 10 }, {}, {}, {}, {}]);
                    } else {
                        test.obs.forEach(function(obs) {
                            const flag = getFlagInfo(obs);
                            drawRow([
                                { text: testName, indent: 10 },
                                { text: fmtResultValue(obs), bold: !!flag, color: flag ? flag.color : cBlack },
                                { text: fmtUnits(obs) },
                                { text: flag ? flag.label : '', bold: !!flag, color: flag ? flag.color : cBlack },
                                { text: fmtRange(obs) }
                            ]);
                            if (obs.comment && obs.comment.trim()) {
                                drawRow(
                                    [{ text: obs.comment.trim(), italic: true, color: cGrey, indent: 20 }, {}, {}, {}, {}],
                                    { rowHeight: RH_COMMENT, textPad: (RH_COMMENT - FS) / 2 }
                                );
                            }
                        });
                    }
                });

            } else {
                const test   = tests[0];
                const obsArr = test ? test.obs : [];

                if (obsArr.length === 0) {
                    drawRow([{ text: conceptName }, {}, {}, {}, {}]);
                } else {
                    obsArr.forEach(function(obs, idx) {
                        const flag = getFlagInfo(obs);
                        drawRow([
                            { text: idx === 0 ? conceptName : '' },
                            { text: fmtResultValue(obs), bold: !!flag, color: flag ? flag.color : cBlack },
                            { text: fmtUnits(obs) },
                            { text: flag ? flag.label : '', bold: !!flag, color: flag ? flag.color : cBlack },
                            { text: fmtRange(obs) }
                        ]);
                        if (obs.comment && obs.comment.trim()) {
                            drawRow(
                                [{ text: obs.comment.trim(), italic: true, color: cGrey, indent: 10 }, {}, {}, {}, {}],
                                { rowHeight: RH_COMMENT, textPad: (RH_COMMENT - FS) / 2 }
                            );
                        }
                    });
                }
            }
        }

        const usablePageH = H - MT - MB;
        encounterGroups.forEach(function(group) {
            const estH = estimateEncounterHeight(group);
            if (estH <= usablePageH && y - MB < estH) {
                page = doc.addPage([W, H]);
                y    = H - MT;
            }
            const rightLabel = group.labId ? 'Lab ID: ' + group.labId : null;
            drawSectionHeader(formatDateTime(group.specimenDatetime), rightLabel);
            group.orders.forEach(renderOrderRows);
        });

        if (pendingOrders.length > 0) {
            drawSectionHeader('Pending');
            pendingOrders.forEach(renderOrderRows);
        }

        const bytes   = await doc.save();
        const blob    = new Blob([bytes], { type: 'application/pdf' });
        const blobUrl = URL.createObjectURL(blob);
        window.open(blobUrl, '_blank');
    }

    static notifyPatient(patientWithOrders, extensionParams) {
        console.log('LabOrderListActions.notifyPatient called', patientWithOrders, extensionParams);
    }
}

// Register entry points expected by the extension framework
window.labOrderListPrintResults  = (p, e) => LabOrderListActions.printResults(p, e);
window.labOrderListNotifyPatient = (p, e) => LabOrderListActions.notifyPatient(p, e);
