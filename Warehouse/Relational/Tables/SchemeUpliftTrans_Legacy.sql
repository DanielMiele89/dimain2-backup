CREATE TABLE [Relational].[SchemeUpliftTrans_Legacy] (
    [FileID]         INT     NOT NULL,
    [RowNum]         INT     NOT NULL,
    [Amount]         MONEY   NOT NULL,
    [AddedDate]      DATE    NULL,
    [FanID]          INT     NOT NULL,
    [OutletID]       INT     NOT NULL,
    [PartnerID]      INT     NOT NULL,
    [IsOnline]       BIT     NOT NULL,
    [weekid]         INT     NULL,
    [ExcludeTime]    BIT     CONSTRAINT [DF_Relational_SchemeUpliftTrans_ExcludeTime] DEFAULT ((0)) NOT NULL,
    [TranDate]       DATE    NOT NULL,
    [IsRetailReport] BIT     NOT NULL,
    [PaymentTypeID]  TINYINT NOT NULL,
    CONSTRAINT [PK_SchemeUpLiftTrans] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC),
    CONSTRAINT [FK_SchemeUpliftTrans_SchemeUpliftTransWeek] FOREIGN KEY ([weekid]) REFERENCES [Relational].[SchemeUpliftTrans_Week] ([ID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Relational_SchemeUpliftTrans_Cover]
    ON [Relational].[SchemeUpliftTrans_Legacy]([AddedDate] ASC, [FanID] ASC, [PartnerID] ASC, [OutletID] ASC, [IsOnline] ASC, [weekid] ASC)
    INCLUDE([Amount]);


GO
CREATE NONCLUSTERED INDEX [IX_Relational_SchemeUpliftTrans_MonthlyReportFacilitate]
    ON [Relational].[SchemeUpliftTrans_Legacy]([IsRetailReport] ASC, [Amount] ASC)
    INCLUDE([AddedDate], [FanID], [OutletID], [PartnerID], [IsOnline], [TranDate], [PaymentTypeID]);


GO
CREATE NONCLUSTERED INDEX [IX_Relational_SchemeUpliftTrans_MemberSalesFacilitate]
    ON [Relational].[SchemeUpliftTrans_Legacy]([PartnerID] ASC, [IsRetailReport] ASC, [Amount] ASC, [AddedDate] ASC)
    INCLUDE([FanID], [OutletID], [IsOnline], [TranDate], [PaymentTypeID]);

