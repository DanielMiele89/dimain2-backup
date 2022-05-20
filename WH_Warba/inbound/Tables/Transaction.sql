CREATE TABLE [inbound].[Transaction] (
    [transactionguid]      VARCHAR (255)    NOT NULL,
    [customerguid]         UNIQUEIDENTIFIER NOT NULL,
    [externalcustomerguid] VARCHAR (255)    NOT NULL,
    [transactiondate]      DATE             NOT NULL,
    [transactiontime]      TIME (7)         NULL,
    [transactionnarrative] VARCHAR (200)    NULL,
    [billingamount]        DECIMAL (9, 2)   NOT NULL,
    [billingcurrencycode]  VARCHAR (3)      NOT NULL,
    [amount]               DECIMAL (9, 2)   NULL,
    [currencycode]         VARCHAR (3)      NULL,
    [merchantid]           VARCHAR (50)     NOT NULL,
    [processcode]          VARCHAR (10)     NOT NULL,
    [merchantcountry]      VARCHAR (30)     NOT NULL,
    [merchantclasscode]    VARCHAR (4)      NOT NULL,
    [cardholderpresent]    VARCHAR (1)      NULL,
    [cardtypeindicator]    VARCHAR (6)      NULL,
    [cardinputmode]        VARCHAR (1)      NULL,
    [reversalindicator]    VARCHAR (1)      NOT NULL
);

