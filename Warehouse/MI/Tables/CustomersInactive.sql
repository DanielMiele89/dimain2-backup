CREATE TABLE [MI].[CustomersInactive] (
    [ID]                 INT     IDENTITY (1, 1) NOT NULL,
    [FanID]              INT     NOT NULL,
    [ActivationDate]     DATE    NOT NULL,
    [ActivationStatusID] TINYINT NOT NULL,
    CONSTRAINT [PK_MI_CustomersInactive] PRIMARY KEY CLUSTERED ([ID] ASC)
);

