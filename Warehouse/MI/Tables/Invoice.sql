CREATE TABLE [MI].[Invoice] (
    [ID]                    INT             IDENTITY (1, 1) NOT NULL,
    [InvoiceNumber]         NVARCHAR (8)    NOT NULL,
    [RangeDateFrom]         DATE            NOT NULL,
    [RangeDateTo]           DATE            NOT NULL,
    [PartnerID]             INT             NULL,
    [Paid]                  BIT             NOT NULL,
    [PreviousTransIncluded] BIT             NOT NULL,
    [InvoiceTitle]          NVARCHAR (300)  NULL,
    [InvoiceDescription]    NVARCHAR (1000) NULL,
    [InvoiceType]           INT             NULL,
    [PartnerTitle]          NVARCHAR (500)  NULL,
    [PartnerName]           NVARCHAR (200)  NULL,
    [InvoiceBankAccountId]  INT             NULL,
    [InvoiceDate]           DATE            NULL,
    [PaymentDue]            DATE            NULL,
    [AdjustedVat]           MONEY           NULL
);

