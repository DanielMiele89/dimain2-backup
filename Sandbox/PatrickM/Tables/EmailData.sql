CREATE TABLE [PatrickM].[EmailData] (
    [FanID]           VARCHAR (50) NOT NULL,
    [Is_Sent]         BIT          NOT NULL,
    [Is_Opened]       BIT          NOT NULL,
    [Is_Unsubscribed] BIT          NOT NULL,
    [Is_Clicked]      BIT          NOT NULL,
    CONSTRAINT [PK_EmailData] PRIMARY KEY CLUSTERED ([FanID] ASC) WITH (FILLFACTOR = 90)
);

