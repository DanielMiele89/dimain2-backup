CREATE TABLE [MI].[SchemeUpliftTrans_Stage] (
    [FileID]         INT     NOT NULL,
    [RowNum]         INT     NOT NULL,
    [Amount]         MONEY   NOT NULL,
    [AddedDate]      DATE    NULL,
    [FanID]          INT     NOT NULL,
    [OutletID]       INT     NOT NULL,
    [PartnerID]      INT     NOT NULL,
    [IsOnline]       BIT     NOT NULL,
    [weekid]         INT     NOT NULL,
    [TranDate]       DATE    NOT NULL,
    [ClubID]         INT     NOT NULL,
    [CompositeID]    BIGINT  NULL,
    [ExcludeNonTime] BIT     CONSTRAINT [DF_MI_SchemeUpliftTrans_Stage_ExcludeNonTime] DEFAULT ((1)) NOT NULL,
    [ExcludeTime]    BIT     CONSTRAINT [DF_MI_SchemeUpliftTrans_Stage_ExcludeTime] DEFAULT ((1)) NOT NULL,
    [ID]             INT     IDENTITY (1, 1) NOT NULL,
    [IsRetailReport] BIT     NOT NULL,
    [PaymentTypeID]  TINYINT NOT NULL,
    CONSTRAINT [PK_SchemeUPliftTrans] PRIMARY KEY CLUSTERED ([ID] ASC)
);

