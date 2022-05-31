CREATE TABLE [Staging].[Customer_PaymentCard] (
    [ID]                INT      IDENTITY (1, 1) NOT NULL,
    [PanID]             INT      NOT NULL,
    [FanID]             INT      NOT NULL,
    [ClubID]            SMALLINT NULL,
    [PaymentCardID]     INT      NULL,
    [PaymentCardTypeID] TINYINT  NULL,
    [DeduplicationDate] DATETIME NULL,
    [StartDate]         DATETIME NULL,
    [EndDate]           DATETIME NULL
);


GO
CREATE NONCLUSTERED INDEX [IDX_FID]
    ON [Staging].[Customer_PaymentCard]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_CL]
    ON [Staging].[Customer_PaymentCard]([ClubID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_PC]
    ON [Staging].[Customer_PaymentCard]([PaymentCardID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_P]
    ON [Staging].[Customer_PaymentCard]([PanID] ASC);

