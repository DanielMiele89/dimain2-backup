CREATE TABLE [MI].[MemberssalesWorking] (
    [ID]                                INT           IDENTITY (1, 1) NOT NULL,
    [Programid]                         INT           NOT NULL,
    [PartnerGroupID]                    INT           NULL,
    [PartnerID]                         INT           NULL,
    [ClientServiceRef]                  NVARCHAR (40) NULL,
    [PaymentTypeID]                     INT           NOT NULL,
    [ChannelID]                         INT           NOT NULL,
    [CustomerAttributeID]               INT           NOT NULL,
    [Mid_SplitID]                       INT           NOT NULL,
    [CumulativeTypeID]                  INT           NOT NULL,
    [PeriodTypeID]                      INT           NOT NULL,
    [DateID]                            INT           NOT NULL,
    [MembersSales]                      MONEY         NOT NULL,
    [MembersTransactions]               INT           NOT NULL,
    [MembersSpenders]                   INT           NOT NULL,
    [MembersCardholders]                INT           NOT NULL,
    [MembersPostActivationSales]        MONEY         NOT NULL,
    [MembersPostActivationTransactions] INT           NOT NULL,
    [MembersPostActivationSpenders]     INT           NOT NULL,
    CONSTRAINT [PK_MI_MemberSalesWorking] PRIMARY KEY CLUSTERED ([ID] ASC)
);

