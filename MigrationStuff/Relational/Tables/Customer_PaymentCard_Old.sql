CREATE TABLE [Relational].[Customer_PaymentCard_Old] (
    [ID]                INT      IDENTITY (1, 1) NOT NULL,
    [PanID]             INT      NOT NULL,
    [FanID]             INT      NOT NULL,
    [ClubID]            SMALLINT NULL,
    [PaymentCardID]     INT      NULL,
    [PaymentCardTypeID] TINYINT  NULL,
    [StartDate]         DATETIME NULL,
    [EndDate]           DATETIME NULL
);


GO
CREATE NONCLUSTERED INDEX [IDX_CL]
    ON [Relational].[Customer_PaymentCard_Old]([ClubID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_PC]
    ON [Relational].[Customer_PaymentCard_Old]([PaymentCardID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_P]
    ON [Relational].[Customer_PaymentCard_Old]([PanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_FID]
    ON [Relational].[Customer_PaymentCard_Old]([FanID] ASC);

