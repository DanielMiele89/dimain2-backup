CREATE TABLE [MI].[CustomerEmailMobileChange] (
    [ID]         INT          IDENTITY (1, 1) NOT NULL,
    [FanID]      INT          NOT NULL,
    [ChangeDate] DATE         NOT NULL,
    [ChangeType] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_MI_CustomerEmailMobileChange] PRIMARY KEY CLUSTERED ([ID] ASC)
);

