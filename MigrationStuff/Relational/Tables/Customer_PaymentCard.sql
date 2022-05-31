CREATE TABLE [Relational].[Customer_PaymentCard] (
    [ID]                INT      IDENTITY (1, 1) NOT NULL,
    [PanID]             INT      NOT NULL,
    [FanID]             INT      NOT NULL,
    [ClubID]            SMALLINT NULL,
    [PaymentCardID]     INT      NULL,
    [PaymentCardTypeID] TINYINT  NULL,
    [StartDate]         DATETIME NULL,
    [EndDate]           DATETIME NULL,
    CONSTRAINT [pk_IDPC] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_PanID]
    ON [Relational].[Customer_PaymentCard]([PanID] ASC)
    ON [nFI_Indexes];


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Relational].[Customer_PaymentCard]([FanID] ASC)
    ON [nFI_Indexes];

