CREATE TABLE [MI].[CAPCustomers] (
    [FanID]     INT  NOT NULL,
    [StartDate] DATE NOT NULL,
    [EndDate]   DATE NOT NULL,
    CONSTRAINT [PK_MI_CAPCustomers] PRIMARY KEY CLUSTERED ([FanID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_MI_CAPCustomers_Cover]
    ON [MI].[CAPCustomers]([StartDate] ASC, [EndDate] ASC);

