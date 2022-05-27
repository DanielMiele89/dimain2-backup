CREATE TABLE [Staging].[SSRS_R0051_OfferSelectionCounts] (
    [id]                INT           IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef] VARCHAR (20)  NULL,
    [HTMID]             INT           NULL,
    [HTM_Description]   VARCHAR (100) NULL,
    [OfferID]           INT           NULL,
    [CashbackRate]      REAL          NULL,
    [MailedCustomers]   INT           NULL,
    [ControlCustomers]  INT           NULL,
    [CommissionRate]    REAL          NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

