@Library('jenkins-multibranch-pipeline-library-demo')_
def label = "slave-${UUID.randomUUID().toString()}"

def helmLint(String chartDir) {
    println "校验 chart 模板"
    sh "helm lint ${chartDir}"
}



// def helmDeploy(Map args) {
//     if (args.debug) {
//         println "Debug 应用"
//         sh "helm upgrade --dry-run --debug --install ${args.name} ${args.chartDir} -f ${args.valuePath} --set image.tag=${args.imageTag} --namespace ${args.namespace}"
//     } else {
//         println "部署应用"
//         sh "helm upgrade --install ${args.name} ${args.chartDir} -f ${args.valuePath} --set image.tag=${args.imageTag} --namespace ${args.namespace}"
//         echo "应用 ${args.name} 部署成功. 可以使用 helm status ${args.name} 查看应用状态"
//     }
// }

podTemplate(label: label, containers: [
  containerTemplate(name: 'golang', image: 'golang:1.14.2-alpine3.11', command: 'cat', ttyEnabled: true),
  containerTemplate(name: 'kaniko', image: 'gcr.io/kaniko-project/executor:debug', command: 'cat', ttyEnabled: true),
  containerTemplate(name: 'helm', image: 'ntops/helm', command: 'cat', ttyEnabled: true),
  containerTemplate(name: 'kubectl', image: 'cnych/kubectl', command: 'cat', ttyEnabled: true)
], serviceAccount: 'jenkins'
// , volumes: [
//   hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
// ]
) 

{
  node(label) {
    def myRepo = checkout scm
    // 获取 git commit id 作为镜像标签
    def imageTag = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
    // 仓库地址
    def registryUrl = "weekendr01.azurecr.io"
    def imageEndpoint = "devops-demo"
    // 镜像
    def image = "${registryUrl}/${imageEndpoint}:${imageTag}"

    stage('下载variables') {
      dir('env_config') {
        git branch: 'master',credentialsId: 'github-ssh-key',url: 'ssh://git@github.com/plusices/devops-demo.git'
          // git branch: 'master', url: 'git@github.com:plusices/devops-demo.git'
      }
      // steps {
      //     sh 'find $P_PATH -name mytestfile'
      //     sh """
      //       cd ../
      //       find `pwd` -name mytestfile
      //     """
      // }
      sh """
        ls env_config
      """
      sayHello 'Tux'
      sh "cp env_config/*.yaml helm/templates/"
    }
    stage('代码编译打包') {
      try {
        container('golang') {
          echo "2.代码编译打包阶段"
          sh """
            export GOPROXY=https://goproxy.cn
            GOOS=linux GOARCH=amd64 go build -v -o demo-app
            """
        }
      } catch (exc) {
        println "构建失败 - ${currentBuild.fullDisplayName}"
        throw(exc)
      }
    }
    stage('构建 Docker 镜像') {
      // dockerBuildPush("${image}")
      dockerBuildPush(
        regcred: 'regcred-uat',
        image: "${image}",
        kubeconfig: 'kubeconfig'
      )
    }
    stage('helm打包'){
      // when {
      //   branch 'master'
      //   // anyOf {
      //   //     environment name: 'DEPLOY_TO', value: 'production'
      //   //     environment name: 'DEPLOY_TO', value: 'staging'
      //   // }
      // }
      if (env.BRANCH_NAME ==~ /(master|release)/) {

        echo "${env.BRANCH_NAME}"
        helmPackage(
          regcred: 'agile168',
          registryUrl: "${registryUrl}"
        )
      }
      
    }
    // stage('构建 Docker 镜像') {
    //   withCredentials([file(credentialsId: 'regcred-uat', variable: 'REGCRED'),file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
    //       container('kaniko') {
    //         echo "3. 构建 Docker 镜像阶段"
    //         sh """
    //           mkdir -p ~/.kube && cp ${KUBECONFIG} ~/.kube/config
    //           cp ${REGCRED} /kaniko/.docker/config.json
    //           cat /kaniko/.docker/config.json
    //           /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --destination=${image} -v=debug
    //           """
    //       }
    //   }
    // }
    // stage('构建 Docker 镜像') {
    //   withCredentials([[$class: 'UsernamePasswordMultiBinding',
    //     credentialsId: 'docker-auth',
    //     usernameVariable: 'DOCKER_USER',
    //     passwordVariable: 'DOCKER_PASSWORD']]) {
    //       container('docker') {
    //         echo "3. 构建 Docker 镜像阶段"
    //         sh """
    //           /kaniko/executor -f `pwd`/Dockerfile -c `pwd`/src --cache=true --destination=${image} --insecure --skip-tls-verify -v=debug
    //           // cat /etc/resolv.conf
    //           // docker login ${registryUrl} -u ${DOCKER_USER} -p ${DOCKER_PASSWORD}
    //           // docker build -t ${image} .
    //           // docker push ${image}
    //           """
    //       }
    //   }
    // }
    stage('运行 Helm') {
      withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
        container('helm') {
          sh "mkdir -p ~/.kube && cp ${KUBECONFIG} ~/.kube/config"
          echo "4.开始 Helm 部署"
          def userInput = input(
            id: 'userInput',
            message: '选择一个部署环境',
            parameters: [
                [
                    $class: 'ChoiceParameterDefinition',
                    choices: "Dev\nQA\nProd",
                    name: 'Env'
                ]
            ]
          )
          echo "部署应用到 ${userInput} 环境"
          // 选择不同环境下面的 values 文件
          if (userInput == "Dev") {
              // deploy dev stuff
          } else if (userInput == "QA"){
              // deploy qa stuff
          } else {
              // deploy prod stuff
          }
          if (env.BRANCH_NAME ==~ /develop/) {
            helmDeploy(
              debug       : false,
              name        : "devops-demo",
              chartDir    : "./helm",
              namespace   : "kube-ops",
              valuePath   : "./helm/my-values.yaml",
              imageTag    : "${imageTag}",
              image       : "${registryUrl}/${imageEndpoint}"
            )
          }
        }

          
      }
    }
    stage('运行 Kubectl') {
      withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
        container('kubectl') {
          sh "mkdir -p ~/.kube && cp ${KUBECONFIG} ~/.kube/config"
          echo "5.查看应用"
          sh "kubectl get all -n kube-ops -l app=devops-demo"
        }
      }
    }
    stage('快速回滚?') {
      withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
        container('helm') {
          sh "mkdir -p ~/.kube && cp ${KUBECONFIG} ~/.kube/config"
          def userInput = input(
            id: 'userInput',
            message: '是否需要快速回滚？',
            parameters: [
                [
                    $class: 'ChoiceParameterDefinition',
                    choices: "Y\nN",
                    name: '回滚?'
                ]
            ]
          )
          if (userInput == "Y") {
            sh "helm rollback devops-demo --namespace kube-ops"
          }
        }
      }
    }
  }
}

