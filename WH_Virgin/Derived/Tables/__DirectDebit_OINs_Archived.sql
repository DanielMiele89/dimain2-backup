CREATE TABLE [Derived].[__DirectDebit_OINs_Archived] (
    [ID]                 INT           NOT NULL,
    [OIN]                INT           NOT NULL,
    [Narrative]          VARCHAR (100) NOT NULL,
    [Status_Description] VARCHAR (30)  NOT NULL,
    [Reason_Description] VARCHAR (30)  NOT NULL,
    [AddedDate]          DATE          NOT NULL,
    [InternalCategory1]  VARCHAR (30)  NULL,
    [InternalCategory2]  VARCHAR (30)  NULL,
    [RBSCategory1]       VARCHAR (30)  NULL,
    [RBSCategory2]       VARCHAR (30)  NULL,
    [StartDate]          DATE          NULL,
    [EndDate]            DATE          NULL,
    [SupplierID]         INT           NULL,
    [SupplierName]       VARCHAR (250) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

