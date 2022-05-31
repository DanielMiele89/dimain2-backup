CREATE TABLE [PatrickM].[balancecomparison] (
    [fanid]           INT        NOT NULL,
    [deactivateddate] DATE       NULL,
    [date]            DATE       NULL,
    [totalearning]    MONEY      NULL,
    [redemptions]     MONEY      NOT NULL,
    [ClubcashPending] SMALLMONEY NULL,
    [CalcPending]     MONEY      NULL,
    [Difference]      MONEY      NULL,
    [Error]           INT        NOT NULL
);

