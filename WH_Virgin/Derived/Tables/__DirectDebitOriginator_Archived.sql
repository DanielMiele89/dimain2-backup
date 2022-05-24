CREATE TABLE [Derived].[__DirectDebitOriginator_Archived] (
    [ID]           INT            NOT NULL,
    [OIN]          INT            NOT NULL,
    [SupplierName] NVARCHAR (100) NOT NULL,
    [Category1]    VARCHAR (50)   NOT NULL,
    [Category2]    VARCHAR (50)   NOT NULL,
    [StartDate]    DATETIME       NOT NULL,
    [EndDate]      DATETIME       NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

