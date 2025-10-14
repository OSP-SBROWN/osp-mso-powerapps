# MSO Power App - Features and Processes Documentation

## Overview
The MSO (Macro Space Optimisation) Power App centralises merchandising and reporting workflows used to balance category space across retail stores and clusters. The application now runs against the `MSO-DB-v6` SQL Server database, allowing the Power App to orchestrate report creation, bay-rule governance, user administration, and performance analysis through curated stored procedures.

**Current Status:** SQL-integrated baseline available
**Last Updated:** October 14, 2025
**Version:** 1.1.0

---

## Table of Contents
1. [Application Architecture](#application-architecture)
2. [Current Features](#current-features)
3. [Data Sources and Connectors](#data-sources-and-connectors)
4. [User Interface Design](#user-interface-design)
5. [Business Processes](#business-processes)
6. [Security and Permissions](#security-and-permissions)
7. [Integration Points](#integration-points)
8. [Deployment and Environment Management](#deployment-and-environment-management)
9. [Future Development Roadmap](#future-development-roadmap)
10. [Development Guidelines](#development-guidelines)
11. [Support and Maintenance](#support-and-maintenance)
12. [Appendix](#appendix)

---

## Application Architecture

### App Type
- **Platform:** Microsoft Power Apps
- **App Type:** Canvas app packaged inside an MSO solution
- **Target Devices:** Desktop (primary), tablet (responsive layout under validation)

### Technical Stack
- **Frontend:** Power Apps Canvas experience with reusable components and gallery-driven navigation
- **Backend:** SQL Server database `MSO-DB-v6`
- **Authentication:** Azure Active Directory (Office 365 logins) mapped to the `Users` table
- **Hosting:** Microsoft Power Platform (online)

### Data Access Layer
- Power Apps connects to SQL via the SQL Server connector (through the enterprise data gateway).
- All write operations are channelled through schema `[ui]` stored procedures to encapsulate logic and auditing.
- Read operations use a blend of stored procedures (for filtered payloads) and direct table/view queries where approved.
- The view `Vw_RVAColumns` is exposed to the app to drive dynamic UI rendering of Report Version Attribute fields.

### Solution Structure
```
MSO Solution
├── Apps
│   └── MSO Power App (Canvas)
├── Data
│   ├── SQL objects (Tables, Views, Functions)
│   └── External data sources (Azure Blob)
├── Automations (planned)
└── Security
    └── Role mappings between Azure AD groups and MSO roles
```

---

## Current Features

### Feature: Report Portfolio Management
**Status:** ✅ Live

**Description:** Maintains the catalogue of merchandising reports, their owners, refresh status, and supporting metadata.

**Functionality:**
- Browse and filter reports by owner, branch, cluster, status, or free text.
- View headline attributes (granularity, last refreshed date, core table readiness).
- Create or update report version attributes with transactional backups.
- Write status updates that feed orchestration and auditing tables.

**Data Interactions:**
- Tables: `ReportVersionAttributes`, `Rva_Archive`, `AppStatusHistory`, `Locations`, `Users`.
- Stored procedures: `[ui].[ReportsGetDetails]`, `[ui].[ReportsUpsertRVARow]`, `[ui].[RVAGetDetails]`.
- View support: `Vw_RVAColumns` for dynamic attribute binding.

**UI Surface:** `scr_ReportCatalogue` gallery and `scr_ReportDetail` form.

### Feature: Report Insight Explorer
**Status:** ✅ Live

**Description:** Presents store, template, and department performance metrics for the selected report.

**Functionality:**
- Toggle between Store (`S`), Template (`T`), and Department (`D`) granularities.
- Compare projected versus current performance at multiple measures (sales, profit, waste, bays).
- Surface target attainment indicators (DoS, case targets, bays).

**Data Interactions:**
- Table: `MSO_Reports` (facts calculated offline by data engineering).
- Stored procedure: `[ui].[NEWGetReportData]` (validated granularity logic and derived KPI deltas).

**UI Surface:** `scr_ReportAnalytics` with segmented controls and data tables.

### Feature: Bay Rule Management
**Status:** ✅ Live

**Description:** Enables business users to configure bay overrides that drive store space recommendations.

**Functionality:**
- Load existing bay rules grouped by drivers, metrics, resize, and rounding themes.
- Capture inline edits as JSON and submit in batches.
- Provide validation feedback when no rules exist for a report.

**Data Interactions:**
- Table: `BayRules`.
- Stored procedures: `[ui].[NEWGetBayRulesByReportID]`, `[ui].[NEW_ManageBayRules]` (JSON ingestion and persistence).

**UI Surface:** `scr_BayRules` with editable data cards and summary chips.

### Feature: User Administration
**Status:** ✅ Live

**Description:** Delegated admin experience for maintaining MSO user access and role metadata.

**Functionality:**
- Create new MSO users with autogenerated `MyID` values.
- Edit user roles, colour modes, hierarchy maintenance flags, and access blockers.
- Enforce guard rails when deleting owners with live reports.

**Data Interactions:**
- Tables: `Users`, `LicencedUsersCurrent` (capacity monitoring).
- Stored procedures: `[ui].[UserManAddUser]`, `[ui].[UserManUpdateUser]`, `[ui].[UserManDelete]`.

**UI Surface:** `scr_UserAdmin` with modal-driven forms.

### Feature: Configuration and Orchestration Dashboard
**Status:** 🔄 In Development

**Description:** Surfaces application level variables, orchestrator queues, and refresh telemetry for operations teams.

**Functionality:**
- Display key-value pairs from `AppVariables` for feature toggles.
- Track report lifecycle stages through `MSO_Orchestrator` flags.
- Review recent status events from `AppStatusHistory`.

**Data Interactions:**
- Tables: `AppVariables`, `MSO_Orchestrator`, `AppStatusHistory`.
- Function: `dbo.SplitString` (used in SQL logic that the app relies on for parsing delimited inputs).

**UI Surface:** `scr_AdminDashboard` (prototype in progress).

### Feature: Hierarchy Maintenance (Phase 2)
**Status:** 📋 Planned

**Description:** A forthcoming module for managing multi-level product hierarchies aligned to merchandising clusters.

**Data Interactions (preview):**
- Tables: `Hierarchy1`, `Hierarchy2`, `Hierarchy3`, `HierarchyVersion`.
- Stored procedures: `[ui].[HierMan2_GetFullHierarchy]`, `[ui].[HierMan2_Insert1]`, `[ui].[HierMan2_Update3]`, `[ui].[HierMan2_DeleteHierarchyVersion]`.

**UI Surface:** `scr_HierarchyManager` (to be built).

---

## Data Sources and Connectors

### Primary Data Sources
| Data Source | Type | Purpose | Connection Method |
|-------------|------|---------|------------------|
| MSO-DB-v6 | SQL Server | System of record for reports, bay rules, users, orchestration data | SQL Server connector via on-premises data gateway |
| AzureBlobStorage | External data source | Provides reference data imports (performance maxima, blob-ledger snapshots) that feed nightly processing | PolyBase external data source consumed by SQL; results consumed indirectly by the app |

### Core Tables by Feature
- **Report Portfolio:** `ReportVersionAttributes`, `Rva_Archive`, `Locations`, `Users`.
- **Analytics:** `MSO_Reports`, `PerfLookup`, `PerfDateExclusions`.
- **Bay Rules:** `BayRules`, `BayRules_Archive`, `BayRulesOldProd*` (legacy reference).
- **User Admin:** `Users`, `LicencedUsersCurrent`, `UserManagedDataVersion`.
- **Configuration:** `AppVariables`, `AppStatusHistory`, `MSO_Orchestrator`.
- **Reference:** `ThemeColours`, `DepartmentColours`, `UnitsOfMeasure`, `Dictionary`.

### Stored Procedure Catalogue (exposed to the app)
| Procedure | Module | Purpose |
|-----------|--------|---------|
| `[ui].[ReportsGetDetails]` | Report Portfolio | Returns filtered list of reports with owner and location context |
| `[ui].[RVAGetDetails]` | Report Portfolio | Hydrates report detail form with all attribute outputs |
| `[ui].[ReportsUpsertRVARow]` | Report Portfolio | Inserts or updates report metadata and archives prior row |
| `[ui].[NEWGetReportData]` | Analytics | Returns metric set filtered by granularity S/T/D |
| `[ui].[NEWGetBayRulesByReportID]` | Bay Rules | Reads override rules for a report |
| `[ui].[NEW_ManageBayRules]` | Bay Rules | Replaces bay rules from JSON payload |
| `[ui].[UserManAddUser]` | User Admin | Creates new user and returns identifier |
| `[ui].[UserManUpdateUser]` | User Admin | Applies partial updates with guard rails |
| `[ui].[UserManDelete]` | User Admin | Deletes a user if no live report ownership exists |

### Views and Functions Used
- `Vw_RVAColumns`: Lists columns of `ReportVersionAttributes` to drive dynamic Power Apps galleries.
- `dbo.SplitString`: Utility function leveraged by SQL logic that the app consumes (for delimited parameters).

---

## User Interface Design

### Navigation Structure
```
Main Navigation
├── Home Dashboard (summary KPIs)
├── Report Catalogue
│   └── Report Detail / Insight Explorer
├── Bay Rule Manager
├── User Administration
└── Admin Dashboard (variables, orchestration) [in development]
```

### Screen Inventory
| Screen Name | Purpose | Primary Audience | Status |
|-------------|---------|------------------|---------|
| scr_Home | Entry point with shortcuts and utilisation metrics | All users | In development |
| scr_ReportCatalogue | Filterable list of reports | Analysts, admins | Live |
| scr_ReportDetail | Maintain report attributes and status | Analysts | Live |
| scr_ReportAnalytics | Review report KPIs by granularity | Analysts, stakeholders | Live |
| scr_BayRules | Configure bay overrides | Analysts | Live |
| scr_UserAdmin | Manage user access and licensing | Admins | Live |
| scr_AdminDashboard | Monitor app variables and orchestration | Admins | In development |

### Design Principles
- Keep base colours aligned with `ThemeColours` and `DepartmentColours` table values.
- Optimise for desktop usage while maintaining responsive container controls for tablet.
- Highlight SQL write operations with confirmation banners sourced from stored procedure success messages.
- Utilise collections (`colReportList`, `colBayRules`, `colUserEdit`) to cache data per screen session.

---

## Business Processes

### Process: Create or Update a Report
**Trigger:** Analyst chooses to create a new report or edit an existing one.

**Steps:**
1. Load existing metadata via `[ui].[RVAGetDetails]` (if editing) and map to form controls.
2. Capture user edits and submit to `[ui].[ReportsUpsertRVARow]`, which archives prior state and upserts `ReportVersionAttributes`.
3. Log status message into `AppStatusHistory` for audit.
4. Refresh catalog view by re-invoking `[ui].[ReportsGetDetails]`.

**Business Rules:**
- Report owners must exist in `Users`.
- Display granularity (`ViewbyStoreTempcatDept`) is limited to S/T/D options.
- Automatic archive row stored in `Rva_Archive` per update.

### Process: Review Report Analytics
**Trigger:** Analyst opens the analytics tab for a report.

**Steps:**
1. App fetches metrics for selected granularity by calling `[ui].[NEWGetReportData]`.
2. Result set is shaped into Power Apps collections for grid display and KPI cards.
3. Users toggle between S/T/D segments; the app reuses cached data or re-queries if not loaded.

**Business Rules:**
- Granularity must be one of S, T, or D (validated in stored procedure).
- Null projected metrics render as blank for clarity.

### Process: Maintain Bay Rules
**Trigger:** Analyst navigates to bay rule editor for a report.

**Steps:**
1. Retrieve current rules using `[ui].[NEWGetBayRulesByReportID]` and populate editable gallery grouped by `Group_Key`.
2. On submit, serialize updates to JSON and send to `[ui].[NEW_ManageBayRules]`.
3. Procedure truncates existing rules for the report and inserts the new set in a transaction.
4. Success or failure message surfaces to the user with row counts.

**Business Rules:**
- Empty payload keeps the history but results in zero rules, flagged visually as a risk.
- Rule groups limited to defined enumerations (Drivers, Metrics, Resize, Rounding).

### Process: Manage User Access
**Trigger:** Admin adds, edits, or removes a user.

**Steps:**
1. For additions, the app executes `[ui].[UserManAddUser]` and captures `@UserID` for immediate UI refresh.
2. For edits, `[ui].[UserManUpdateUser]` is passed only changed fields, relying on SQL `COALESCE` logic to leave other values unchanged.
3. Deletion attempts trigger `[ui].[UserManDelete]`, which blocks removal if associated reports exist.

**Business Rules:**
- Colour mode restricted to Light (`L`) or Dark (`D`).
- Report ownership check ensures data integrity.
- Licensing metrics pulled from `LicencedUsersCurrent` inform capacity dashboards.

### Process: Monitor Orchestration (Emerging)
**Trigger:** Admin reviews refresh queues.

**Steps:**
1. Dashboard queries `MSO_Orchestrator` for records where `IsFetched`, `IsCalculated`, or `IsDeleted` flags are pending.
2. Status history pulled from `AppStatusHistory` to provide narrative timeline.
3. AppVariables highlight feature toggles impacting orchestration behaviour.

**Business Rules:**
- Only admins can access advanced orchestration data.
- Future enhancements will include manual retry triggers (Power Automate integration).

---

## Security and Permissions

### Security Model
- Authentication through Azure AD ensures only licensed users access the app.
- Application roles (Analyst, Admin) are mapped to Azure AD groups and mirrored in `Users` table flags (`FunctionalUser`, `AdminUser`).
- Row-level visibility is enforced by filtering datasets on `UserID` where applicable (e.g., report ownership).

### Security Roles
| Role | Description | Permissions |
|------|-------------|-------------|
| Analyst | Access to report catalogue, analytics, bay rule editing | Read/write on report and bay rule stored procedures |
| Admin | Full analyst rights plus user management and configuration screens | Includes execution rights on user procedures and orchestration tables |
| Viewer (planned) | Read-only analytics | Read-only stored procedure wrappers |

### Data Security
- Sensitive write operations encapsulated in `[ui]` schema stored procedures with explicit `TRY/CATCH` blocks.
- `Rva_Archive` maintains change history for recovery and audit.
- No direct table writes from the app; gateway policies enforce stored procedure-only access.

---

## Integration Points

### SQL Stored Procedures and Views
- Power Apps executes approved `[ui]` stored procedures defined in the SQL project to enforce business rules.
- `Vw_RVAColumns` supports dynamic column discovery for the report detail form.

### External Systems
- Azure Blob external data sources (`AzureBlobStorage`, `PerfmaxBlobSource`) are consumed by SQL ETL jobs; results surface in tables the app reads (e.g., performance maxima feeds `MSO_Reports`).
- Legacy macros and staging tables (e.g., `MacroSpaceDates`, `Locations_Staging`) are populated by offline pipelines and serve as read-only references to the app.

### Planned Integrations
- Power Automate flows for refresh orchestration notifications.
- Power BI report embedding for advanced analytics once dataset is published.

---

## Deployment and Environment Management

### Environments
| Environment | Purpose | Notes |
|-------------|---------|-------|
| Development | Canvas app build and SQL schema changes | Uses dev instance of `MSO-DB-v6` |
| Test | UAT with representative data volume | Requires data refresh from production snapshots |
| Production | Live environment for MSO users | Strict stored procedure access controls |

### Deployment Process
1. Apply SQL schema updates through the `MSO-DB-v6.sqlproj` pipeline (build verified via `dotnet build`).
2. Export managed Power Apps solution tagged with semantic version (matching SQL release tag).
3. Import to Test, validate stored procedure connectivity via gateway.
4. Conduct UAT sign-off covering report creation, analytics retrieval, bay rule update, and user management scenarios.
5. Promote SQL and app packages to Production and run smoke tests.

### Version Control
- SQL project files tracked under `SQL/MSO-DB-v6` with DACPAC outputs for deployment.
- Power App metadata exported routinely to source control (planned integration).
- Change log maintained in this document and Azure DevOps work items.

---

## Future Development Roadmap

### Phase 1: Foundation (Complete)
- [x] Project initialisation
- [x] SQL schema import and documentation linkage
- [x] Core report, bay rule, and user modules connected to SQL

### Phase 2: Core Enhancements (In Progress)
- [ ] Complete Admin Dashboard for orchestration insight
- [ ] Implement hierarchy maintenance screens backed by `HierMan2_*` procedures
- [ ] Add in-app telemetry for stored procedure failures

### Phase 3: Advanced Capabilities (Planned)
- [ ] Integrate Power Automate alerts and refresh triggers
- [ ] Embed Power BI visuals for macro performance analysis
- [ ] Introduce sandbox testing mode leveraging staging tables

### Phase 4: Optimisation (Planned)
- [ ] Performance tuning of heavy stored procedures (e.g., `NEWGetReportData`)
- [ ] Caching strategy for static tables (Theme colours, dictionaries)
- [ ] Accessibility certification and responsive enhancements

---

## Development Guidelines

### Naming Conventions
- **Screens:** `scr_<Feature>` (e.g., `scr_ReportCatalogue`)
- **Collections:** `col<Context>` (e.g., `colReportList`)
- **Variables:** `var<Intent>` (e.g., `varSelectedReportID`)
- **Components:** `cmp_<Purpose>`
- **Stored Procedure Actions:** `sp<ProcedureName>` (Power Apps data source alias)

### Code Standards
- Use `With()` and local collections to minimise repeated SQL calls.
- Surface stored procedure success and error messages in notification banners for transparency.
- Document complex formulas with concise comments, especially when transforming stored procedure outputs.
- Guard all write operations with optimistic concurrency checks where applicable (compare timestamps or hash totals).

### Testing Procedures
- Smoke tests after each deployment: report create/update, analytics read, bay rule submit, user add/edit/delete.
- Regression pack to validate edge cases (e.g., deleting bay rules, report owner transfers).
- Load testing of `[ui].[NEWGetReportData]` when dataset volumes change significantly.

---

## Support and Maintenance

### Key Contacts
| Role | Name | Email | Responsibilities |
|------|------|-------|-----------------|
| Product Owner | _TBD_ | _TBD_ | Prioritise features and approve releases |
| Technical Lead | _TBD_ | _TBD_ | Owns Power App and SQL alignment |
| Power Platform Admin | _TBD_ | _TBD_ | Manages environments and connectors |

### Documentation Updates
Update this document:
- After each SQL or Power App release touching user flows.
- When new stored procedures are surfaced to the app.
- Following post-implementation reviews or incident learnings.
- During quarterly governance checkpoints.

### Change Log
| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-14 | 1.1.0 | Documented SQL-backed features and interactions | System |
| 2025-10-14 | 1.0.0 | Initial documentation template | System |

---

## Appendix

### Glossary
- **Bay Rules:** Configurable overrides that determine bay allocations per report.
- **RVA:** Report Version Attributes; core metadata set describing a merchandising report.
- **DoS:** Days of Stock target metric.
- **DOSCOS:** Days of stock vs case pack alignment metric stored in analytics tables.
- **Orchestrator:** Table tracking backend processing stages for report refreshes.

### References
- [Power Apps Documentation](https://learn.microsoft.com/power-apps/)
- [SQL Server Power Apps Connector](https://learn.microsoft.com/power-apps/maker/canvas-apps/connections/connection-azure-sql-database)
- [Power Platform ALM Guidance](https://learn.microsoft.com/power-platform/alm/overview)

---

*This is a living document and should evolve alongside the MSO Power App and its SQL assets.*