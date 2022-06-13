CREATE TABLE [inbound].[Matched_Transaction] (
    [transactionguid]       UNIQUEIDENTIFIER NOT NULL,
    [externaltransactionid] VARCHAR (255)    NOT NULL,
    [customerguid]          UNIQUEIDENTIFIER NOT NULL,
    [customersourceid]      VARCHAR (255)    NOT NULL,
    [offercode]             UNIQUEIDENTIFIER NOT NULL,
    [timestamp]             DATETIME         NOT NULL,
    [transactionamount]     DECIMAL (8, 2)   NOT NULL,
    [cashbackearned]        DECIMAL (8, 2)   NOT NULL,
    [offerrate]             DECIMAL (5, 2)   NOT NULL,
    [merchantid]            VARCHAR (50)     NOT NULL,
    [retailerid]            UNIQUEIDENTIFIER NOT NULL,
    [vatrate]               DECIMAL (5, 2)   NOT NULL,
    [vatamount]             DECIMAL (5, 2)   NOT NULL,
    [commisionrate]         DECIMAL (5, 2)   NOT NULL,
    [netamount]             DECIMAL (5, 2)   NOT NULL,
    [grossamount]           DECIMAL (5, 2)   NOT NULL,
    PRIMARY KEY CLUSTERED ([transactionguid] ASC) WITH (FILLFACTOR = 90)
);

