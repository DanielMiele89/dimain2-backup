CREATE TABLE [MI].[RetailerTrackingAcquirer] (
    [ConsumerCombinationID] INT     NOT NULL,
    [AcquirerID]            TINYINT NOT NULL,
    [AnnualSpend]           MONEY   CONSTRAINT [DF_MI_RetailerTrackingAcquirer_AnnualSpend] DEFAULT ((0)) NOT NULL,
    [TransactedOnDate]      BIT     CONSTRAINT [DF_MI_RetailerTrackingAcquirer_TransactedOnDate] DEFAULT ((0)) NOT NULL,
    [TransactedDate]        DATE    NULL,
    CONSTRAINT [PK_MI_RetailerTrackingAcquirer] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

