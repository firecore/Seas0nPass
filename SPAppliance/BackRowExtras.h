
#import <objc/runtime.h>
template <typename Type_>
static inline Type_ &MSHookIvar(id self, const char *name) {
Ivar ivar(class_getInstanceVariable(object_getClass(self), name));
void *pointer(ivar == NULL ? NULL : reinterpret_cast<char *>(self) + ivar_getOffset(ivar));
return *reinterpret_cast<Type_ *>(pointer);
}
