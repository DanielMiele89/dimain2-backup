CREATE TABLE [InsightArchive].[MorrisonsLaunch_MorrisonsAMEXMatchedCustomers_20180530] (
    [ID_Morrisons]            BIGINT        NULL,
    [ID_Amex]                 BIGINT        NULL,
    [FirstNameHashed_AMEX]    VARCHAR (100) NULL,
    [SurnameHashed_AMEX]      VARCHAR (100) NULL,
    [AddressLine1Hashed_AMEX] VARCHAR (100) NULL,
    [PostCodeHashed_AMEX]     VARCHAR (100) NULL,
    [EmailHashed_AMEX]        VARCHAR (100) NULL,
    [MatchedOn]               VARCHAR (23)  NOT NULL
);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[MorrisonsLaunch_MorrisonsAMEXMatchedCustomers_20180530] TO [New_PIIRemoved]
    AS [dbo];

