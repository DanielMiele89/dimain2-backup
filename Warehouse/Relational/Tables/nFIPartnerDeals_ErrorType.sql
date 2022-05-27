CREATE TABLE [Relational].[nFIPartnerDeals_ErrorType] (
    [ErrorID]       INT           NOT NULL,
    [Message]       VARCHAR (255) NOT NULL,
    [ColumnToCheck] VARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([ErrorID] ASC)
);

