CREATE TABLE [MI].[CustomerActiveStatus_TEST] (
    [FanID]              INT     NOT NULL,
    [ActivatedDate]      DATE    NOT NULL,
    [DeactivatedDate]    DATE    NULL,
    [OptedOutDate]       DATE    NULL,
    [IsRBS]              BIT     NOT NULL,
    [ActivationMethodID] TINYINT CONSTRAINT [DF_MI_CustomerActiveStatus_ActivationMethodID_TEST] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_MI_CustomerActiveStatus_TEST] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

