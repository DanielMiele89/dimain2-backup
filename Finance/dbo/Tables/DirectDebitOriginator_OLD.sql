CREATE TABLE [dbo].[DirectDebitOriginator_OLD] (
    [DirectDebitOriginatorID] INT            NOT NULL,
    [OIN]                     INT            NOT NULL,
    [SupplierName]            NVARCHAR (100) NOT NULL,
    [Category1]               VARCHAR (50)   NOT NULL,
    [Category2]               VARCHAR (50)   NOT NULL,
    [StartDate]               DATETIME       NOT NULL,
    [EndDate]                 DATETIME       NULL,
    [CreatedDateTime]         DATETIME2 (7)  NOT NULL,
    [UpdatedDateTime]         DATETIME2 (7)  NOT NULL,
    CONSTRAINT [PK__DirectDe__41CD6AEB8807A3C9_OLD] PRIMARY KEY CLUSTERED ([DirectDebitOriginatorID] ASC)
);

