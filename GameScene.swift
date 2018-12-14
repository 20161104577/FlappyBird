//
//  GameScene.swift
//  FlappyBird
//
//  Created by Nate Murray on 6/2/14.
//  Copyright (c) 2014 Fullstack.io. All rights reserved.
//
//布置场景

import SpriteKit
//备注：SKPhysicsContactDelegate是代理协议
class GameScene: SKScene, SKPhysicsContactDelegate{
    
    
    var bird:SKSpriteNode!
    //小鸟
    var skyColor:SKColor!
    //设置管道缺口大小
    let verticalPipeGap = 180.0
    //向上管纹理
    var pipeTextureUp:SKTexture!
    //向下管纹理
    var pipeTextureDown:SKTexture!
    //存储所有上下管道
    var pipes:SKNode!
    
    var movePipesAndRemove:SKAction!
    
    //储存陆地，天空和水管
    var moving:SKNode!
    
    var canRestart = Bool()
    var scoreLabelNode:SKLabelNode!
    
    //分数定义
    var score = NSInteger()
    
    // 设置物理体的标示符
    let birdCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    
    override func didMove(to view: SKView) {
        
        canRestart = true
        
        //给场景添加一个物理体，限制了游戏范围，确保精灵不会跑出屏幕
       // self.physicsBody = SKPhysicsBody(edgeLoopFrom:self.frame)
        // 设置重力
        self.physicsWorld.gravity = CGVector( dx: 0.0, dy: -5.0 )
        //物理世界的触碰检测代理为场景自己
        self.physicsWorld.contactDelegate = self
        
        // 设置背景颜色
        skyColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        self.backgroundColor = skyColor
        //初始化变量
        moving = SKNode()
        self.addChild(moving)
        //储存水管的变量pipes也加到moving里面
        pipes = SKNode()
        moving.addChild(pipes)//管道
        
        // 地面
        let groundTexture = SKTexture(imageNamed: "land")
        groundTexture.filteringMode = .nearest // shorter form for SKTextureFilteringMode.Nearest
        
        let moveGroundSprite = SKAction.moveBy(x: -groundTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.02 * groundTexture.size().width * 2.0))
        let resetGroundSprite = SKAction.moveBy(x: groundTexture.size().width * 2.0, y: 0, duration: 0.0)
        //永远移动 组动作
        let moveGroundSpritesForever = SKAction.repeatForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]))
        //每帧的移动设置
        for i in 0 ..< 2 + Int(self.frame.size.width / ( groundTexture.size().width * 2 )) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            //位置坐标定义
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2.0)
        //移动动作调用
            sprite.run(moveGroundSpritesForever)
            moving.addChild(sprite)
        }
        
        // 天空
        let skyTexture = SKTexture(imageNamed: "sky")
        skyTexture.filteringMode = .nearest
        //设置天空动画的移动
        let moveSkySprite = SKAction.moveBy(x: -skyTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.1 * skyTexture.size().width * 2.0))
        let resetSkySprite = SKAction.moveBy(x: skyTexture.size().width * 2.0, y: 0, duration: 0.0)
        //需要一直移动的动作
        let moveSkySpritesForever = SKAction.repeatForever(SKAction.sequence([moveSkySprite,resetSkySprite]))
        
        for i in 0 ..< 2 + Int(self.frame.size.width / ( skyTexture.size().width * 2 )) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: skyTexture)
            sprite.setScale(2.0)
            sprite.zPosition = -20
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2.0 + groundTexture.size().height * 2.0)
            sprite.run(moveSkySpritesForever)
            moving.addChild(sprite)
        }
        
        // 创建管道结构
        pipeTextureUp = SKTexture(imageNamed: "PipeUp")
        pipeTextureUp.filteringMode = .nearest
        pipeTextureDown = SKTexture(imageNamed: "PipeDown")
        pipeTextureDown.filteringMode = .nearest
        
        // 设置管道的移动行为
        let distanceToMove = CGFloat(self.frame.size.width + 2.0 * pipeTextureUp.size().width)
        let movePipes = SKAction.moveBy(x: -distanceToMove, y:0.0, duration:TimeInterval(0.01 * distanceToMove))
        let removePipes = SKAction.removeFromParent()
        movePipesAndRemove = SKAction.sequence([movePipes, removePipes])
        
        // 随机量产管道
        let spawn = SKAction.run(spawnPipes)
        let delay = SKAction.wait(forDuration: TimeInterval(2.0))//每轮管道生产的时间
        let spawnThenDelay = SKAction.sequence([spawn, delay])//量产延迟
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)//持续生产
        self.run(spawnThenDelayForever)
        //设置小鸟飞行的动画
        //小鸟贴图设置
        let birdTexture1 = SKTexture(imageNamed: "bird-01")
        birdTexture1.filteringMode = .nearest
        let birdTexture2 = SKTexture(imageNamed: "bird-02")
        birdTexture2.filteringMode = .nearest
        let birdTexture3 = SKTexture(imageNamed: "bird-03")
        birdTexture2.filteringMode = .nearest
        let birdTexture4 = SKTexture(imageNamed: "bird-04")
        birdTexture2.filteringMode = .nearest
        //小鸟贴图循环
        let anim = SKAction.animate(with: [birdTexture1, birdTexture2,birdTexture3, birdTexture4], timePerFrame: 0.2)
        //拍打翅膀的特效，四个贴图循环
        let flap = SKAction.repeatForever(anim)
        //小鸟
        bird = SKSpriteNode(texture: birdTexture1)
        bird.setScale(2.0)
        bird.position = CGPoint(x: self.frame.size.width * 0.35, y:self.frame.size.height * 0.6)
        bird.run(flap)
        
        //给场景添加小鸟的物理体，防止小鸟跑出屏幕
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory
        //设置小鸟受外力影响的属性值
        //isDynamic的作用是设置这个物理体当前是否会受到物理环境的影响，默认是true
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        
        
        self.addChild(bird)
        
        //配置陆地物理体
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: groundTexture.size().height)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundTexture.size().height * 2.0))
        ground.physicsBody?.isDynamic = false
        
        //当前物理体
        ground.physicsBody?.categoryBitMask = worldCategory
        self.addChild(ground)
        
        // 初始化标签并创建一个保存分数的标签
        score = 0
        scoreLabelNode = SKLabelNode(fontNamed:"MarkerFelt-Wide")
        scoreLabelNode.position = CGPoint( x: self.frame.midX, y: 3 * self.frame.size.height / 4 )
        scoreLabelNode.zPosition = 100
        scoreLabelNode.text = String(score)
        self.addChild(scoreLabelNode)
        
    }
    
    func spawnPipes() {
        let pipePair = SKNode()
        pipePair.position = CGPoint( x: self.frame.size.width + pipeTextureUp.size().width * 2, y: 0 )
        //z值的节点（用于排序）负数z是“进入”屏幕，正数z是“出去”屏幕
        pipePair.zPosition = -10
        
        //随机的Y值
        let height = UInt32( self.frame.size.height / 4)
        let y = Double(arc4random_uniform(height) + height)
        
        let pipeDown = SKSpriteNode(texture: pipeTextureDown)
        pipeDown.setScale(2.0)
        pipeDown.position = CGPoint(x: 0.0, y: y + Double(pipeDown.size.height) + verticalPipeGap)
        
        //配置向下的管道的物理体
        pipeDown.physicsBody = SKPhysicsBody(rectangleOf: pipeDown.size)
        pipeDown.physicsBody?.isDynamic = false
        pipeDown.physicsBody?.categoryBitMask = pipeCategory
        pipeDown.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipeDown)
        
        let pipeUp = SKSpriteNode(texture: pipeTextureUp)
        pipeUp.setScale(2.0)
        pipeUp.position = CGPoint(x: 0.0, y: y)
        
        //配置向上的管道的物理体
        pipeUp.physicsBody = SKPhysicsBody(rectangleOf: pipeUp.size)
        pipeUp.physicsBody?.isDynamic = false
        pipeUp.physicsBody?.categoryBitMask = pipeCategory
        pipeUp.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipeUp)
        
        //用于加分的隐藏题，在越过管道的瞬间碰撞，然后记分+1
        let contactNode = SKNode()
        contactNode.position = CGPoint( x: pipeDown.size.width + bird.size.width / 2, y: self.frame.midY )
        contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize( width: pipeUp.size.width, height: self.frame.size.height ))
        contactNode.physicsBody?.isDynamic = false
        contactNode.physicsBody?.categoryBitMask = scoreCategory
        contactNode.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(contactNode)
        
        pipePair.run(movePipesAndRemove)
        pipes.addChild(pipePair)
        
    }
    //场景重置函数
    func resetScene (){
        // 将鸟移至初始位置并复位速度
        bird.position = CGPoint(x: self.frame.size.width / 2.5, y: self.frame.midY)
        bird.physicsBody?.velocity = CGVector( dx: 0, dy: 0 )
        //碰撞位淹码
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.speed = 1.0
        bird.zRotation = 0.0
        
        // 清除所有现有管道
        pipes.removeAllChildren()
        
        // 重新设置 _canRestart
        canRestart = false
        
        // 重置分数
        score = 0
        scoreLabelNode.text = String(score)
        
        // 重新开始动画
        moving.speed = 1
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if moving.speed > 0  {
            for _ in touches { //是否需要所有的接触
                bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                //施加一个均匀作用于物理体的推力
                bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 30))
            }
        } else if canRestart {
            self.resetScene()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* 在每帧呈现之前调用，调整让头先碰到地面 */
        let value = bird.physicsBody!.velocity.dy * ( bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001 )
        bird.zRotation = min( max(-1, value), 0.5 )
    }
    //碰撞协议的函数
    func didBegin(_ contact: SKPhysicsContact) {
        if moving.speed > 0 {
            if ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory {
                //   将小鸟飞行与score链接起来
                score += 1
                scoreLabelNode.text = String(score)
                
                // 为分数增量添加一些视觉反馈
                scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
            } else {
                //碰到管道就停下来
                moving.speed = 0
                
                bird.physicsBody?.collisionBitMask = worldCategory
                bird.run(  SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1), completion:{self.bird.speed = 0 })
                
                
                // 如果检测到接触就闪光
                self.removeAction(forKey: "flash")
                self.run(SKAction.sequence([SKAction.repeat(SKAction.sequence([SKAction.run({
                    self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
                    }),SKAction.wait(forDuration: TimeInterval(0.05)), SKAction.run({
                        self.backgroundColor = self.skyColor
                        }), SKAction.wait(forDuration: TimeInterval(0.05))]), count:4), SKAction.run({
                            self.canRestart = true
                            })]), withKey: "flash")
            }
        }
    }
}
