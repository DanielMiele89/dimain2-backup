CREATE TABLE [Staging].[CustomerActivationPeriod] (
    [ID]              INT  NOT NULL,
    [FanID]           INT  NOT NULL,
    [ActivationStart] DATE NOT NULL,
    [ActivationEnd]   DATE NULL,
    CONSTRAINT [PK_Staging_CustomerActivationPeriod] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_FanID]
    ON [Staging].[CustomerActivationPeriod]([FanID] ASC)
    INCLUDE([ID], [ActivationStart]) WITH (FILLFACTOR = 80);

