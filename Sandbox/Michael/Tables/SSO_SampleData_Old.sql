CREATE TABLE [Michael].[SSO_SampleData_Old] (
    [customer_id]           INT              NOT NULL,
    [action_datetime]       DATETIME         NULL,
    [action_type]           VARCHAR (37)     NOT NULL,
    [login_type]            VARCHAR (7)      NOT NULL,
    [session_length_(secs)] NUMERIC (32, 15) NULL,
    [customer_type]         VARCHAR (21)     NOT NULL,
    [account_type]          VARCHAR (7)      NOT NULL,
    [bank]                  VARCHAR (7)      NOT NULL,
    [region]                VARCHAR (30)     NULL,
    [postcode_district]     VARCHAR (4)      NULL
);

