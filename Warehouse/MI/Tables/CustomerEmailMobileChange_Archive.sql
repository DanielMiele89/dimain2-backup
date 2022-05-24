CREATE TABLE [MI].[CustomerEmailMobileChange_Archive] (
    [ID]         INT          IDENTITY (1, 1) NOT NULL,
    [FanID]      INT          NOT NULL,
    [ChangeDate] DATE         NOT NULL,
    [ChangeType] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_MI_CustomerEmailMobileChange_Archive] PRIMARY KEY NONCLUSTERED ([ID] ASC) WITH (FILLFACTOR = 95)
);


GO
CREATE CLUSTERED INDEX [cx_stuff]
    ON [MI].[CustomerEmailMobileChange_Archive]([FanID] ASC, [ChangeDate] ASC) WITH (FILLFACTOR = 80);

