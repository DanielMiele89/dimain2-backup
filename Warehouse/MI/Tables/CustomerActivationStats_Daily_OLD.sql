CREATE TABLE [MI].[CustomerActivationStats_Daily_OLD] (
    [ID]                         INT  IDENTITY (1, 1) NOT NULL,
    [RunDate]                    DATE NOT NULL,
    [ActivatedOnlinePrevDay]     INT  NOT NULL,
    [ActivatedOfflinePrevDay]    INT  NOT NULL,
    [OptedOutPrevDay]            INT  NOT NULL,
    [DeactivatedPrevDay]         INT  NOT NULL,
    [ActivatedOnlineCumulative]  INT  NOT NULL,
    [ActivatedOfflineCumulative] INT  NOT NULL,
    [DeactivatedCumulative]      INT  NOT NULL,
    [OptedOutCumulative]         INT  NOT NULL,
    [OptedOutOnlinePrevDay]      INT  NULL,
    [OptedOutOnlineCumulative]   INT  NULL,
    [OptedOutOfflinePrevDay]     INT  NULL,
    [OptedOutOfflineCumulative]  INT  NULL
);

