CREATE TABLE [MI].[RBSContactlessTrans] (
    [FileID]     INT     NOT NULL,
    [RowNum]     INT     NOT NULL,
    [FanID]      INT     NOT NULL,
    [TranTypeID] TINYINT NOT NULL,
    [Spend]      MONEY   NOT NULL,
    [Earnings]   MONEY   NOT NULL,
    [AddedDate]  DATE    NOT NULL
);

