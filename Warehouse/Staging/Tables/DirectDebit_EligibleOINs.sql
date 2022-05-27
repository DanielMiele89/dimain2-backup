CREATE TABLE [Staging].[DirectDebit_EligibleOINs] (
    [OIN]          INT            NOT NULL,
    [Category1]    VARCHAR (50)   NOT NULL,
    [Category2]    VARCHAR (50)   NOT NULL,
    [SupplierName] NVARCHAR (100) NOT NULL,
    [StartDate]    DATE           NOT NULL,
    PRIMARY KEY CLUSTERED ([OIN] ASC)
);

