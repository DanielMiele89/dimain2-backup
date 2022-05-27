CREATE TABLE [Relational].[nFIPartnerDeals_Relationship_V2] (
    [ID]          INT          IDENTITY (1, 1) NOT NULL,
    [Description] VARCHAR (50) NOT NULL,
    [IsRevenue]   BIT          NOT NULL,
    [IsRetailer]  BIT          NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

