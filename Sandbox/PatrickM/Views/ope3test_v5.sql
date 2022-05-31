create view patrickm.ope3test_v5 as 
select fanid, a.CINID, c.BrandID, Propensity
from sandbox.patrickm.ope3testcustomers as a
left join (select * from Warehouse.Prototype.OPECustomerPropensity
				union
			select ID, 1111 as BrandID, CINID, Propensity from warehouse.Prototype.EnergySwitchCustomerPropensity 
			) as c
	on a.CINID = c.CINID
	where EndDate is NULL