CREATE TABLE [dbo].[CustomerLapse] (
    [FanID]    INT          NOT NULL,
    [LapsFlag] VARCHAR (50) NOT NULL,
    [Date]     DATE         NOT NULL,
    CONSTRAINT [PK_CustomerLapse] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

