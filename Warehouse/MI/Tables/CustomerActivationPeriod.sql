CREATE TABLE [MI].[CustomerActivationPeriod] (
    [ID]              INT  IDENTITY (1, 1) NOT NULL,
    [FanID]           INT  NOT NULL,
    [ActivationStart] DATE NOT NULL,
    [ActivationEnd]   DATE NULL,
    [AddedDate]       DATE NULL,
    [UpdatedDate]     DATE NULL,
    CONSTRAINT [PK_MI_CustomerActivationPeriod] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_FanID]
    ON [MI].[CustomerActivationPeriod]([FanID] ASC)
    INCLUDE([ID], [ActivationStart]) WITH (FILLFACTOR = 80);

