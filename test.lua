function merge(table1, table2)
	local resTable = {}
	for k,v in pairs(table1) do
		resTable[k] = v
	end
	for k,v in pairs(table2) do
		resTable[k] = v
	end
	return resTable
end

a = {"a","a","b","c","d"}
b = {1,2,3}
c = {a="1", b="2"}
res = merge(a,c)

for k,v in pairs(res) do
	print(k,v)
end