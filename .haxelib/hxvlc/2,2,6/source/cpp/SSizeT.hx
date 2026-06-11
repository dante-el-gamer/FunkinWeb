package cpp;

#if windows
@:include('vlc/vlc.h')
#end
@:native("ssize_t")
@:scalar
@:coreType
@:notNull
extern abstract SSizeT from Int to Int {}
