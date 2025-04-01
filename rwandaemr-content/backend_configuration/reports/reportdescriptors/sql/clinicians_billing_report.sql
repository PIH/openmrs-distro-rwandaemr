				SELECT
				DATE_FORMAT(mbpsb.service_date,'%d/%m/%Y') as DateTaken,
                dp.name as Department,
				concat(COALESCE(c.given_name,'')," ",COALESCE(c.middle_name,'')," ",COALESCE(c.family_name,'')) as Creator,
				concat(COALESCE(pn.given_name,'')," ",COALESCE(pn.middle_name,'')," ",COALESCE(pn.family_name,'')) as 'Beneficiary',
				pi.identifier as 'Patient ID',
                mbfsp.name as ITEM,
				mbpsb.unit_price as Price,
				mbpsb.quantity as Quantity,
                mbpsb.unit_price*mbpsb.quantity as Total,
				i.name as 'Insurance Name',
				concat(ir.rate,'%') as Percent,
				mbpsb.unit_price*mbpsb.quantity as 'Total Bill Amount',
				round(((mbpsb.unit_price*mbpsb.quantity)*(ir.rate/100)),0) as 'Insurance Due',
				round(((mbpsb.unit_price*mbpsb.quantity)*(100-ir.rate))/100,0) as 'Patient Due',
				CASE
					WHEN mbpsb.is_paid = 1 THEN 'Paid'
					WHEN mbpsb.is_paid = 0 THEN 'Not Paid'
					ELSE 'Uknown'
				END AS 'Payment Status',
				CASE
					WHEN mbpsb.is_paid = 1 THEN round(((mbpsb.unit_price*mbpsb.quantity)*(100-ir.rate))/100,0)
					ELSE 'Not Paid'
				END AS 'Paid Amount',
				concat(COALESCE(np.given_name,'')," ",COALESCE(np.middle_name,'')," ",COALESCE(np.family_name,'')) as Collector
				FROM moh_bill_patient_service_bill mbpsb
				inner join moh_bill_consommation cn on mbpsb.consommation_id =cn.consommation_id
				inner join moh_bill_patient_bill pb on cn.patient_bill_id = pb.patient_bill_id
				inner join moh_bill_payment bp on pb.patient_bill_id= bp.patient_bill_id
				inner join moh_bill_beneficiary bn on cn.beneficiary_id=bn.beneficiary_id
				inner join moh_bill_global_bill gb on cn.global_bill_id=gb.global_bill_id
				inner join moh_bill_insurance_policy e on bn.insurance_policy_id = e.insurance_policy_id
				inner join moh_bill_insurance i on e.insurance_id = i.insurance_id
				inner join moh_bill_department dp on cn.department_id=dp.department_id
				inner join moh_bill_insurance_rate ir on i.insurance_id = ir.insurance_id
				inner join moh_bill_billable_service mbbs on mbpsb.billable_service_id = mbbs.billable_service_id
				inner join moh_bill_facility_service_price mbfsp on mbbs.facility_service_price_id = mbfsp.facility_service_price_id
                inner join moh_bill_paid_service_bill pdsb on mbpsb.patient_service_bill_id = pdsb.patient_service_bill_id
				inner join patient_identifier pi on bn.patient_id = pi.patient_id
				inner join person p on bn.patient_id = p.person_id
				inner join users b on pb.creator = b.user_id
				inner join person_name c on b.person_id = c.person_id
				inner join person_name pn on bn.patient_id = pn.person_id
				inner join users u on bp.creator = u.user_id
				inner join person_name np on u.person_id = np.person_id
				WHERE mbpsb.voided=0
				and ir.retired=0
				and DATE(mbpsb.created_date) between :startDate  and :endDate
				order by i.name ;