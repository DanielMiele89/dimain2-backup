CREATE TABLE [Prod].[NobleFanAttributes] (
    [CompositeID]             BIGINT    NOT NULL,
    [Primacy]                 CHAR (1)  NOT NULL,
    [AccountKey]              CHAR (16) NULL,
    [IsJoint]                 BIT       NULL,
    [ControlGroupNumber]      TINYINT   NOT NULL,
    [IsControl]               BIT       NOT NULL,
    [ReportGroup]             TINYINT   NOT NULL,
    [TreatmentGroup]          TINYINT   NOT NULL,
    [LaunchGroup]             CHAR (4)  NULL,
    [OriginalEmailPermission] BIT       NOT NULL,
    [OriginalDMPermission]    BIT       NOT NULL,
    [EmailOriginallySupplied] BIT       NOT NULL,
    [CurrentEmailPermission]  BIT       NULL,
    [CurrentDMPermission]     BIT       NULL,
    [IsOmitted]               BIT       NOT NULL,
    [MonthOfBirth]            SMALLINT  NULL,
    [YearOfBirth]             SMALLINT  NULL,
    CONSTRAINT [PK_NobleFanAttributes] PRIMARY KEY CLUSTERED ([CompositeID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[Prod].[NobleFanAttributes] TO [stuart]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Prod].[NobleFanAttributes] TO [Suraj]
    AS [dbo];

