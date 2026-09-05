function stage8_k2_rtc_write_json(filename,value)
temporary = [char(filename) '.tmp'];
assert(~isfile(temporary),'RTC:Temporary','Existing temporary file: %s',temporary);
fid = fopen(temporary,'w','n','UTF-8');
assert(fid>=0);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
clear cleanup
[ok,message] = movefile(temporary,filename,'f');
assert(ok,'RTC:AtomicWrite','%s',message);
end
