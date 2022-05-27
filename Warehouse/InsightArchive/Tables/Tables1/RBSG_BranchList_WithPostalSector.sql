CREATE TABLE [InsightArchive].[RBSG_BranchList_WithPostalSector] (
    [SortCode]       VARCHAR (50) NULL,
    [Brand]          VARCHAR (50) NULL,
    [ClubID]         INT          NOT NULL,
    [BranchName]     VARCHAR (50) NULL,
    [ProjectRainbow] BIT          NULL,
    [Address1]       VARCHAR (50) NULL,
    [Address2]       VARCHAR (50) NULL,
    [Address3]       VARCHAR (50) NULL,
    [Address4]       VARCHAR (50) NULL,
    [PostCode]       VARCHAR (50) NULL,
    [PostalSector]   VARCHAR (6)  NULL,
    [MD]             VARCHAR (50) NULL,
    [PlannedClosure] BIT          NULL
);

