CREATE TABLE [Derived].[RetailerCommercialTerms] (
    [ID]            INT             NOT NULL,
    [ClubID]        INT             NULL,
    [PartnerID]     INT             NULL,
    [ManagedBy]     VARCHAR (100)   NULL,
    [StartDate]     DATE            NULL,
    [EndDate]       DATE            NULL,
    [Override]      DECIMAL (32, 3) NULL,
    [Publisher]     DECIMAL (5, 2)  NULL,
    [Reward]        DECIMAL (5, 2)  NULL,
    [FixedOverride] BIT             NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);




GO
GRANT SELECT
    ON OBJECT::[Derived].[RetailerCommercialTerms] TO [ExcelQuery_DataOps]
    AS [dbo];

