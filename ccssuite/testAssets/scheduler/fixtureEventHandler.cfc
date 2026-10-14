component implements="CFIDE.scheduler.ITaskEventHandler" output="false" {
        public boolean function onTaskStart(struct context){
                return false;
        }

        public void function onTaskEnd(struct context){}
        public void function onMisfire(struct context){}
        public void function onError(struct context){}
        public void function execute(struct context){}
}