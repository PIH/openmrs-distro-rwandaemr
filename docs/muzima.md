# mUzima (optional add-on)

[mUzima](https://www.muzima.org) is an Android client for OpenMRS. Health workers use the mUzima app to download
patient cohorts and forms, collect data offline and send it back to OpenMRS. On the server, the **muzimacore**
module (`org.openmrs.module.muzimacore`) provides the REST services the app uses, form and cohort management, and
the queue that turns submitted data into encounters and observations.

The distributions in this repository don't include muzimacore. Where a server needs it, install it by hand as
described below. Kirehe and Kayonza have had mUzima servers (`kirehe-muzima`, `kayonza-muzima`), and Butaro
production runs muzimacore 2.6.1-SNAPSHOT.

## Why it isn't in the distribution

The distribution build downloads every module from a Maven repository. muzimacore 2.6.1-SNAPSHOT isn't published
to any repository the build uses, and its source is in the private `muzima/openmrs-module-muzimacore-enterprise`
repository. The public `muzima/openmrs-module-muzimacore` repository is at 1.8.1-SNAPSHOT and hasn't changed
since 2022.

## Getting the module

- **From the mUzima team:** ask them for the OMOD, and for the commit it was built from.
- **From an existing server:** copy `muzimacore-<version>.omod` from that server's modules directory.
- **From source,** if you have access to `muzima/openmrs-module-muzimacore-enterprise`:

  ```bash
  mvn clean package -DskipTests -Dproject.build.sourceEncoding=ISO-8859-1
  # the OMOD is omod/target/muzimacore-<version>.omod
  ```

  Butaro production's OMOD was built from `master@b8910657` (2024-04-30), the last commit at 2.6.1-SNAPSHOT. A
  build of that commit matches it apart from build metadata and compiler output: production's was built with
  JDK 11, which places a few casts differently from JDK 8.

## Requirements

muzimacore 2.6.1-SNAPSHOT requires these modules, which every distribution here already includes:

| Module | Minimum version |
|---|---|
| webservices.rest | 2.1 |
| reportingcompatibility | 1.5.13 |

It also integrates with xforms, idgen and reporting when they are present.

## Installing

1. Stop OpenMRS.
2. Copy the OMOD into the modules directory of the OpenMRS application data directory:
   - OpenMRS SDK server: `~/openmrs/<server>/modules/`
   - `openmrs/openmrs-core` Docker image: `/openmrs/data/modules/`
3. Start OpenMRS. On its first start the module creates its `muzima_*` tables, its settings and five scheduled
   tasks (below).
4. Check that the module started: **Administration → Manage Modules** lists "Muzima Core Module", and the
   Administration page has an **mUzima** section.

**Each time you deploy a new distribution build,** check that muzimacore is still in the modules directory and
copy it back if it isn't. The distribution doesn't know about the module, so a deployment that replaces the modules
directory removes it.

### Servers that already ran muzimacore

Butaro's database already has the module's tables and data. If a distribution build is deployed without
muzimacore, the data stays in the database, but the mUzima app can't sync and submitted data isn't processed until
the module is installed again. Install the same or a later version than the server ran before.

## Configuring

Everything is under **Administration → mUzima** (`/openmrs/module/muzimacore/view.list`):

| Link | Use |
|---|---|
| View Dashboard | the module's dashboard |
| Program Setup | setup configurations: what the app downloads for a program (forms, cohorts, locations, providers, concepts) |
| mUzima Forms | upload mUzima HTML forms or ODK/JavaRosa XML forms |
| Cohort Definitions | cohorts the app downloads |
| Patient Reports, Report Dataset Definitions | patient reports generated for download |
| View Queue Data, View Error Data, View Potential Duplicates | submitted data waiting to be processed, data that failed, and possible duplicate registrations |

The module's own settings aren't OpenMRS global properties. They are at
`/openmrs/module/muzimacore/view.list#/settings`, and include patient identifier auto-generation and its source,
cohort auto-download, the concepts used for media (audio, video, image and file) observations, and GPS,
relationships and event logging.

The module adds these scheduled tasks (**Administration → Manage Scheduler**):

| Task | Does |
|---|---|
| Process mUzima Queue Data | turns submitted data into OpenMRS data |
| mUzima Dynamic Cohort task | updates cohort membership |
| mUzima dataset definition processor | evaluates report dataset definitions |
| Auto Generate Patient Reports | generates patient reports (daily) |
| mUzima downloadable obs processor | prepares observations for download |

## Using

1. Create an OpenMRS user for each person who will use the app, with the roles their work needs.
2. Under **Program Setup**, create a setup configuration with the forms and cohorts they need.
3. In the mUzima app, enter the server URL (for example `https://<server>/openmrs`), log in with the OpenMRS user
   and choose the setup configuration.
4. The app downloads the cohorts and forms. Completed forms are sent to the server's queue, and the "Process mUzima
   Queue Data" task saves them as OpenMRS data. Submissions that fail appear under **View Error Data**, where they can be
   corrected and processed again.

For anything beyond this, see the mUzima documentation or ask the mUzima team.
