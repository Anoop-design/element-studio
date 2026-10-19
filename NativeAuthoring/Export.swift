import Foundation
import simd

struct AssetMetadata: Codable {
  let id: String, name: String, sub: String, description: String, geometry: String
}
struct BufferRange: Codable { let offset: Int, count: Int }
struct ExportBatch: Codable {
  let name: String, role: String, color: [Double], roughness: Double, metallic: Double,
    explode: [Double]
  let positions: BufferRange, normals: BufferRange, uv: BufferRange, indices: BufferRange
}
struct PrintSurface: Encodable {
  let width = 101, height = 113, xMin = -1.25, yMin = -1.4, xStep = 2.5 / 100, yStep = 2.8 / 112
  var front: [Double?] = [], back: [Double?] = []
  init(_ root: Node) {
    let sampler = SurfaceSampler(root)
    for row in 0..<height {
      for col in 0..<width {
        let r = sampler.range(xMin + Double(col) * xStep, yMin + Double(row) * yStep)
        front.append(r?.front)
        back.append(r?.back)
      }
    }
  }
}
struct ExportManifest: Encodable {
  let id: String, name: String, sub: String, description: String, geometry: String
  let generator = "ElementStudioAuthor Swift v1"
  let printSurface: PrintSurface?
  let batches: [ExportBatch]
}
struct MeshExport {
  let manifest: ExportManifest
  let binary: Data
}
func exportMesh(_ root: Node, id: String, metadata: AssetMetadata, live: Bool = false) -> MeshExport
{
  struct Batch {
    let name: String
    let material: Material
    let explode: V3
    var mesh: Mesh
  }
  struct Key: Hashable {
    let path: String
    let material: Material
    let explode: V3
  }
  var batches: [Batch] = []
  var lookup: [Key: Int] = [:]
  func walk(_ node: Node, _ parent: simd_double4x4, _ names: [String], _ offset: V3) {
    if live && node.fixture { return }
    let world = parent * node.matrix
    var path = names
    var explode = offset
    if let delta = node.explode {
      path.append(node.name)
      let v = parent * SIMD4(delta, 0)
      explode += V3(v.x, v.y, v.z)
    }
    if var mesh = node.mesh, !mesh.indices.isEmpty {
      mesh.transform(world)
      let key = Key(path: path.joined(separator: "/"), material: node.material, explode: explode)
      if let index = lookup[key] {
        batches[index].mesh.append(mesh)
      } else {
        lookup[key] = batches.count
        batches.append(
          Batch(
            name: path.last ?? "Fixed details", material: node.material, explode: explode,
            mesh: mesh))
      }
    }
    for child in node.children { walk(child, world, path, explode) }
  }
  walk(root, matrix_identity_double4x4, [], .zero)
  var data = Data()
  var output: [ExportBatch] = []
  func floats(_ values: [Float]) -> BufferRange {
    let range = BufferRange(offset: data.count, count: values.count)
    for value in values {
      precondition(value.isFinite, "Non-finite exported vertex")
      var bits = value.bitPattern.littleEndian
      withUnsafeBytes(of: &bits) { data.append(contentsOf: $0) }
    }
    return range
  }
  func integers(_ values: [UInt32]) -> BufferRange {
    let range = BufferRange(offset: data.count, count: values.count)
    for value in values {
      var bits = value.littleEndian
      withUnsafeBytes(of: &bits) { data.append(contentsOf: $0) }
    }
    return range
  }
  for batch in batches {
    // Weld exact exported attributes, preserving UV seams and separate cap normals.
    var vertices: [Vertex] = []
    var indices: [UInt32] = []
    var map: [[UInt32]: UInt32] = [:]
    for index in batch.mesh.indices {
      let v = batch.mesh.vertices[index]
      let values: [Double] = [v.p.x, v.p.y, v.p.z, v.n.x, v.n.y, v.n.z, v.uv.x, 1 - v.uv.y]
      let key = values.map { Float($0).bitPattern }
      if let mapped = map[key] {
        indices.append(mapped)
      } else {
        let mapped = UInt32(vertices.count)
        map[key] = mapped
        vertices.append(v)
        indices.append(mapped)
      }
    }
    let positions = floats(vertices.flatMap { [Float($0.p.x), Float($0.p.y), Float($0.p.z)] })
    let normals = floats(vertices.flatMap { [Float($0.n.x), Float($0.n.y), Float($0.n.z)] })
    let uv = floats(vertices.flatMap { [Float($0.uv.x), Float(1 - $0.uv.y)] })
    let idx = integers(indices)
    output.append(
      ExportBatch(
        name: batch.name, role: batch.material.role, color: batch.material.color,
        roughness: batch.material.roughness, metallic: batch.material.metallic,
        explode: [batch.explode.x, batch.explode.y, batch.explode.z], positions: positions,
        normals: normals, uv: uv, indices: idx))
  }
  // The live projection must exclude fixture text just like its exported mesh.
  func removeFixtures(_ node: Node) {
    node.children.removeAll { $0.fixture }
    for child in node.children { removeFixtures(child) }
  }
  if live { removeFixtures(root) }
  let manifest = ExportManifest(
    id: id, name: metadata.name, sub: metadata.sub, description: metadata.description,
    geometry: metadata.geometry, printSurface: live ? PrintSurface(root) : nil, batches: output)
  return MeshExport(manifest: manifest, binary: data)
}

enum AuthorError: Error, CustomStringConvertible {
  case argument(String)
  var description: String {
    switch self {
    case .argument(let message): message
    }
  }
}
struct AuthorOptions {
  var output = "build/mesh-export", ids: [String]?, live = false, overwrite = false, textures = true
  init(_ arguments: [String]) throws {
    var i = 0
    while i < arguments.count {
      let flag = arguments[i]
      i += 1
      switch flag {
      case "--output", "--ids":
        guard i < arguments.count, !arguments[i].hasPrefix("--") else {
          throw AuthorError.argument("Missing value for \(flag)")
        }
        let value = arguments[i]
        i += 1
        if flag == "--output" {
          output = value
        } else {
          ids = value.split(separator: ",").map(String.init)
          if ids!.isEmpty { throw AuthorError.argument("--ids requires at least one object") }
        }
      case "--live": live = true
      case "--overwrite": overwrite = true
      case "--no-textures": textures = false
      default: throw AuthorError.argument("Unknown argument: \(flag). Use --help.")
      }
    }
  }
}
@main struct ElementStudioAuthor {
  static func main() {
    do { try run() } catch {
      FileHandle.standardError.write(Data("ElementStudioAuthor: \(error)\n".utf8))
      exit(1)
    }
  }
  static func run() throws {
    let args = Array(CommandLine.arguments.dropFirst())
    if args.contains("--help") {
      print(
        """
        Native Daybeat geometry authoring (macOS 13+, Swift, CoreGraphics).
        swift run -c release ElementStudioAuthor [options]
          --output PATH       Candidate directory (default: build/mesh-export)
          --ids ID,ID         Selected catalogue IDs, including ribbon-curved,
                              ribbon-ceramic, returning-folded, returning-ceramic
          --live              Omit fixture inscriptions; emit front/back print surfaces
          --overwrite         Explicitly replace candidates in the output directory
          --no-textures       Skip procedural photo and sand texture generation
        Output IDs are versioned with -swift-v1. Review in the native simulator
        before promoting a new revision. Preserved Resources files are immutable.
        """)
      return
    }
    let options = try AuthorOptions(args)
    let resources = Bundle.module
    let catalogue = try JSONDecoder().decode(
      [AssetMetadata].self,
      from: Data(contentsOf: resources.url(forResource: "Catalogue", withExtension: "json")!))
    let variants =
      catalogue.map(\.id) + [
        "returning-folded", "returning-ceramic", "ribbon-curved", "ribbon-ceramic",
      ]
    let selected = options.ids ?? variants
    guard Set(selected).count == selected.count, selected.allSatisfy(variants.contains) else {
      throw AuthorError.argument(
        "Unknown or duplicate ID; valid IDs: \(variants.joined(separator:", "))")
    }
    let out = URL(fileURLWithPath: options.output, isDirectory: true).standardizedFileURL
    // --overwrite is for disposable candidates, never a license to replace published revisions.
    let repoResources = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .deletingLastPathComponent().appendingPathComponent("Resources").standardizedFileURL
    guard out.resolvingSymlinksInPath() != repoResources.resolvingSymlinksInPath() else {
      throw AuthorError.argument(
        "Export to a candidate folder, review it, then promote a new version explicitly.")
    }
    let assetIDs = selected.map { (options.live ? "live-" : "") + $0 + "-swift-v1" }
    let names =
      assetIDs.flatMap { ["ElementStudio-\($0).bin", "ElementStudio-\($0).json"] }
      + (options.textures
        ? ["ElementStudio-photo-swift-v1.png", "ElementStudio-sand-swift-v1.png"] : [])
    if !options.overwrite,
      let collision = names.first(where: {
        FileManager.default.fileExists(atPath: out.appendingPathComponent($0).path)
      })
    {
      throw AuthorError.argument(
        "Refusing to overwrite \(collision); choose a new output or explicit --overwrite")
    }
    let font = try OutlineFont(
      url: resources.url(forResource: "Helvetiker", withExtension: "json")!)
    let mark = try BrandMark(url: resources.url(forResource: "DaybeatMark", withExtension: "json")!)
    let builder = DaybeatShapes(font: font, mark: mark)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
    for (choice, id) in zip(selected, assetIDs) {
      let parts = choice.split(separator: "-")
      let base = String(parts[0])
      let study = parts.count > 1 ? String(parts[1]) : nil
      print("Building \(choice)…")
      fflush(stdout)
      let root = builder.build(base, study: study, live: options.live)
      let original = catalogue.first { $0.id == base }!
      let descriptions: [String: String] = [
        "returning-folded":
          "A thin amber band turns through space; its shoulders widen into the arrowhead.",
        "returning-ceramic":
          "A full ceramic loop with a soft oval section and a naturally widening arrowhead.",
        "ribbon":
          "One thin strip turns over at the top and flows into two unequal tails. A fine binding follows both edges.",
        "ribbon-curved": "A rounded cast bookmark with a calm broad face and a slim satin edge.",
        "ribbon-ceramic":
          "A softly rounded ceramic bookmark, with olive glaze and restrained low relief lettering.",
      ]
      let metadata = AssetMetadata(
        id: original.id, name: original.name, sub: original.sub,
        description: descriptions[choice] ?? original.description,
        geometry: descriptions[choice] == nil
          ? original.geometry
          : "A continuous indexed shell with a rounded section, real reverse and shaped end caps. Its material and clay views use the same geometry."
      )
      let result = exportMesh(root, id: id, metadata: metadata, live: options.live)
      try result.binary.write(
        to: out.appendingPathComponent("ElementStudio-\(id).bin"), options: .atomic)
      try encoder.encode(result.manifest).write(
        to: out.appendingPathComponent("ElementStudio-\(id).json"), options: .atomic)
      print("\(id): \(result.manifest.batches.count) native batches, \(result.binary.count) bytes")
    }
    if options.textures { try NativeTextures.write(to: out) }
  }
}
