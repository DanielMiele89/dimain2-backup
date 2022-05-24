CREATE TABLE [APW].[ControlExposedPercentageMakeup] (
    [ID]                  TINYINT    IDENTITY (1, 1) NOT NULL,
    [FirstTranYear]       SMALLINT   NOT NULL,
    [PrePeriodSpendID]    TINYINT    NOT NULL,
    [ExposedSize]         INT        CONSTRAINT [DF_APW_ControlExposedPercentageMakeup_ExposedSize] DEFAULT ((0)) NOT NULL,
    [ExposedShare]        FLOAT (53) CONSTRAINT [DF_APW_ControlExposedPercentageMakeup_ExposedShare] DEFAULT ((0)) NOT NULL,
    [ControlSize]         INT        CONSTRAINT [DF_APW_ControlExposedPercentageMakeup_ControlSize] DEFAULT ((0)) NOT NULL,
    [ControlShare]        FLOAT (53) CONSTRAINT [DF_APW_ControlExposedPercentageMakeup_ControlShare] DEFAULT ((0)) NOT NULL,
    [AdjustedControlSize] INT        CONSTRAINT [DF_APW_ControlExposedPercentageMakeup_AdjustedControlSize] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_APW_ControlExposedPercentageMakeup] PRIMARY KEY CLUSTERED ([ID] ASC)
);

