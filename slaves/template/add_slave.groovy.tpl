import hudson.model.Node.Mode
import hudson.slaves.*
import jenkins.model.Jenkins
DumbSlave dumb = new DumbSlave(
        "${jenkins_node_name}",
        "/home/jenkins",
        new JNLPLauncher()
        )
dumb.setNodeDescription("${jenkins_slave_description }")
dumb.setNumExecutors(${jenkins_slave_nb_executor })
dumb.setLabelString("${jenkins_slave_labels}")
dumb.setMode(Mode.NORMAL)
dumb.setRetentionStrategy(RetentionStrategy.INSTANCE)
Jenkins.instance.addNode(dumb)
println "Agent ${jenkins_node_name} added"