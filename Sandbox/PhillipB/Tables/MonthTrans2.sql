CREATE TABLE [PhillipB].[MonthTrans2] (
    [FanID]               INT           NULL,
    [AccountSegmentation] VARCHAR (255) NULL,
    [NomineeStatus]       INT           NULL,
    [PaymentTypeID]       INT           NULL,
    [Month]               DATE          NULL,
    [Transactions]        FLOAT (53)    NULL,
    [TableKey]            INT           NOT NULL,
    PRIMARY KEY CLUSTERED ([TableKey] ASC) WITH (FILLFACTOR = 90)
);

