CREATE TABLE [MI].[ActivatedCustomer] (
    [ID]      INT  NOT NULL,
    [CINID]   INT  NOT NULL,
    [FanID]   INT  NOT NULL,
    [InDate]  DATE NOT NULL,
    [OutDate] DATE NULL,
    CONSTRAINT [PK_MI_ActivatedCustomer] PRIMARY KEY CLUSTERED ([ID] ASC)
);

