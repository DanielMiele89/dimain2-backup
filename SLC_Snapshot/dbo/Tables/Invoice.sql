CREATE TABLE [dbo].[Invoice] (
    [ID]                    INT             IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
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
    [AdjustedVat]           MONEY           NULL,
    [PONumber]              NVARCHAR (100)  NULL,
    CONSTRAINT [PK_Invoice] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [IX_Invoice_InvoiceNumber] UNIQUE NONCLUSTERED ([InvoiceNumber] ASC)
);

