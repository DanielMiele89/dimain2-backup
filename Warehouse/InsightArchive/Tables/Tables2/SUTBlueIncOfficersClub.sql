CREATE TABLE [InsightArchive].[SUTBlueIncOfficersClub] (
    [FileID]         INT     NOT NULL,
    [RowNum]         INT     NOT NULL,
    [Amount]         MONEY   NOT NULL,
    [AddedDate]      DATE    NULL,
    [FanID]          INT     NOT NULL,
    [OutletID]       INT     NOT NULL,
    [PartnerID]      INT     NOT NULL,
    [IsOnline]       BIT     NOT NULL,
    [WeekID]         INT     NULL,
    [ExcludeTime]    BIT     NOT NULL,
    [TranDate]       DATE    NOT NULL,
    [IsRetailReport] BIT     NOT NULL,
    [PaymentTypeID]  TINYINT NOT NULL,
    CONSTRAINT [PK_InsightArchive_SUTBlueIncOfficersClub] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);

