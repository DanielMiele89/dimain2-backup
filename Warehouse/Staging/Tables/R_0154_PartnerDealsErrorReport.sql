CREATE TABLE [Staging].[R_0154_PartnerDealsErrorReport] (
    [RowID]         INT           IDENTITY (1, 1) NOT NULL,
    [ErrorID]       INT           NOT NULL,
    [Message]       VARCHAR (255) NULL,
    [ColumnToCheck] VARCHAR (255) NULL,
    [ID]            INT           NOT NULL,
    [ClubID]        INT           NULL,
    [ClubName]      VARCHAR (100) NULL,
    [PartnerID]     INT           NULL,
    [PartnerName]   VARCHAR (100) NULL,
    [ManagedBy]     VARCHAR (100) NULL,
    [StartDate]     DATE          NULL,
    [EndDate]       DATE          NULL,
    [Override]      FLOAT (53)    NULL,
    [Publisher]     FLOAT (53)    NULL,
    [Reward]        FLOAT (53)    NULL,
    [FixedOverride] BIT           NULL,
    PRIMARY KEY CLUSTERED ([RowID] ASC)
);

